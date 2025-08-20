--------------------------------------------------------
--  DDL for Package Body REGRA_COENDER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "REGRA_COENDER_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/01/2018
  -- DESCRICAO: Criacao de regra de coenderecamento - usuarios enderecados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/09/2019  Novos atributos descricao e grupo
  -- Silvia            01/10/2019  Retirada do papel_id.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_grupo_id               IN regra_coender.grupo_id%TYPE,
  p_cliente_id             IN regra_coender.cliente_id%TYPE,
  p_produto_cliente_id     IN regra_coender.produto_cliente_id%TYPE,
  p_tipo_job_id            IN regra_coender.tipo_job_id%TYPE,
  p_descricao              IN VARCHAR2,
  p_flag_ativo             IN VARCHAR2,
  p_comentario             IN VARCHAR2,
  p_vetor_usuario_end_id   IN VARCHAR2,
  p_vetor_usuario_coend_id IN VARCHAR2,
  p_regra_coender_id       OUT regra_coender.regra_coender_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id LONG;
  v_usuario_id       usuario.usuario_id%TYPE;
  v_regra_coender_id regra_coender.regra_coender_id%TYPE;
  v_cod_acao         tipo_acao.codigo%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt               := 0;
  p_regra_coender_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_grupo_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM grupo
    WHERE grupo_id = p_grupo_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo de cliente não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_cliente_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE pessoa_id = p_cliente_id
      AND produto_cliente_id = p_produto_cliente_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto de cliente cliente não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tipo_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_job
    WHERE tipo_job_id = p_tipo_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de job não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_vetor_usuario_coend_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário a ser coendereçado foi informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_comentario)) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_regra_coender.nextval
    INTO v_regra_coender_id
    FROM dual;
  --
  INSERT INTO regra_coender
   (regra_coender_id,
    empresa_id,
    cliente_id,
    produto_cliente_id,
    tipo_job_id,
    flag_ativo,
    comentario,
    descricao,
    grupo_id)
  VALUES
   (v_regra_coender_id,
    p_empresa_id,
    zvl(p_cliente_id, NULL),
    zvl(p_produto_cliente_id, NULL),
    zvl(p_tipo_job_id, NULL),
    p_flag_ativo,
    TRIM(p_comentario),
    TRIM(p_descricao),
    zvl(p_grupo_id, NULL));
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de enderecados
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_end_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_ender
    WHERE regra_coender_id = v_regra_coender_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO usuario_ender
     (regra_coender_id,
      usuario_id)
    VALUES
     (v_regra_coender_id,
      v_usuario_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de coenderecados
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_coend_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   IF nvl(v_usuario_id, 0) > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_coender
     WHERE regra_coender_id = v_regra_coender_id
       AND usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO usuario_coender
      (regra_coender_id,
       usuario_id)
     VALUES
      (v_regra_coender_id,
       v_usuario_id);
    END IF;
   END IF;
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_coender
   WHERE regra_coender_id = v_regra_coender_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário a ser coendereçado foi informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(v_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'INCLUIR',
                   v_identif_objeto,
                   v_regra_coender_id,
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
  p_regra_coender_id := v_regra_coender_id;
  p_erro_cod         := '00000';
  p_erro_msg         := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/01/2018
  -- DESCRICAO: Atualizacao de regra de coenderecamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/09/2019  Novos atributos descricao e grupo
  -- Silvia            01/10/2019  Retirada do papel_id.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_regra_coender_id   IN regra_coender.regra_coender_id%TYPE,
  p_grupo_id           IN regra_coender.grupo_id%TYPE,
  p_cliente_id         IN regra_coender.cliente_id%TYPE,
  p_produto_cliente_id IN regra_coender.produto_cliente_id%TYPE,
  p_tipo_job_id        IN regra_coender.tipo_job_id%TYPE,
  p_descricao          IN VARCHAR2,
  p_comentario         IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_cod_acao       tipo_acao.codigo%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra de coendereçamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_grupo_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM grupo
    WHERE grupo_id = p_grupo_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo de cliente não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_cliente_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE pessoa_id = p_cliente_id
      AND produto_cliente_id = p_produto_cliente_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto de cliente cliente não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tipo_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_job
    WHERE tipo_job_id = p_tipo_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de job não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(TRIM(p_comentario)) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- gera xml do log antes da atualizacao
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE regra_coender
     SET cliente_id         = zvl(p_cliente_id, NULL),
         produto_cliente_id = zvl(p_produto_cliente_id, NULL),
         tipo_job_id        = zvl(p_tipo_job_id, NULL),
         comentario         = TRIM(p_comentario),
         descricao          = TRIM(p_descricao),
         grupo_id           = zvl(p_grupo_id, NULL)
   WHERE regra_coender_id = p_regra_coender_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'ALTERAR',
                   v_identif_objeto,
                   p_regra_coender_id,
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
 PROCEDURE usuario_ender_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/05/2015
  -- DESCRICAO: Atualizacao de regra de coenderecamento - usuarios enderecados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/07/2016  Novos parametros (cliente, produto_cliente, tipo_job)
  -- Silvia            24/11/2017  Ativacao/inativacao da regra.
  -- Silvia            18/01/2018  Retirada de parametros pois proc passou a ser apenas de
  --                               alteracao.
  -- Silvia            13/09/2019  Permite regra sem usuarios enderecados (indicando qualquer)
  -- Silvia            01/10/2019  Retirada do papel_id.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id LONG;
  v_usuario_id       usuario.usuario_id%TYPE;
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
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra de coendereçamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM usuario_ender
   WHERE regra_coender_id = p_regra_coender_id;
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = nvl(v_usuario_id, 0);
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe (' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_ender
    WHERE regra_coender_id = p_regra_coender_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO usuario_ender
     (regra_coender_id,
      usuario_id)
    VALUES
     (p_regra_coender_id,
      v_usuario_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'ALTERAR',
                   v_identif_objeto,
                   p_regra_coender_id,
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
 END usuario_ender_atualizar;
 --
 --
 PROCEDURE usuario_coender_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/05/2015
  -- DESCRICAO: Atualização de regra de coenderecamento - usuarios coenderecados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/10/2019  Retirada do papel_id.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id LONG;
  v_usuario_id       usuario.usuario_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra de coendereçamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  DELETE FROM usuario_coender
   WHERE regra_coender_id = p_regra_coender_id;
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = nvl(v_usuario_id, 0);
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe (' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_coender
    WHERE regra_coender_id = p_regra_coender_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO usuario_coender
     (regra_coender_id,
      usuario_id)
    VALUES
     (p_regra_coender_id,
      v_usuario_id);
   END IF;
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_coender
   WHERE regra_coender_id = p_regra_coender_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário a ser coendereçado foi informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'ALTERAR',
                   v_identif_objeto,
                   p_regra_coender_id,
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
 END usuario_coender_atualizar;
 --
 --
 PROCEDURE flag_ativo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/11/2017
  -- DESCRICAO: Atualização do flag_ativo da regra
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
  p_flag_ativo        IN VARCHAR2,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
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
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
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
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_comentario)) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE regra_coender
     SET flag_ativo = TRIM(p_flag_ativo),
         comentario = TRIM(p_comentario)
   WHERE regra_coender_id = p_regra_coender_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_regra_coender_id);
  v_compl_histor   := 'Ativação/inativação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'ALTERAR',
                   v_identif_objeto,
                   p_regra_coender_id,
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
 END flag_ativo_atualizar;
 --
 --
 PROCEDURE copiar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/11/2015
  -- DESCRICAO: copia de regra de coenderecamento
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/09/2019  Novos atributos descricao e grupo
  -- Silvia            01/10/2019  Retirada do papel_id.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_regra_coender_id      IN regra_coender.regra_coender_id%TYPE,
  p_regra_coender_novo_id OUT regra_coender.regra_coender_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_xml_atual        CLOB;
  v_regra_coender_id regra_coender.regra_coender_id%TYPE;
  --
 BEGIN
  v_qt                    := 0;
  p_regra_coender_novo_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra de coendereçamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_regra_coender.nextval
    INTO v_regra_coender_id
    FROM dual;
  --
  INSERT INTO regra_coender
   (regra_coender_id,
    empresa_id,
    cliente_id,
    produto_cliente_id,
    tipo_job_id,
    flag_ativo,
    descricao,
    grupo_id)
   SELECT v_regra_coender_id,
          empresa_id,
          cliente_id,
          produto_cliente_id,
          tipo_job_id,
          'N',
          descricao,
          grupo_id
     FROM regra_coender
    WHERE regra_coender_id = p_regra_coender_id;
  --
  INSERT INTO usuario_ender
   (regra_coender_id,
    usuario_id)
   SELECT v_regra_coender_id,
          usuario_id
     FROM usuario_ender
    WHERE regra_coender_id = p_regra_coender_id;
  --
  INSERT INTO usuario_coender
   (regra_coender_id,
    usuario_id)
   SELECT v_regra_coender_id,
          usuario_id
     FROM usuario_coender
    WHERE regra_coender_id = p_regra_coender_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(v_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'INCLUIR',
                   v_identif_objeto,
                   v_regra_coender_id,
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
  p_regra_coender_novo_id := v_regra_coender_id;
  p_erro_cod              := '00000';
  p_erro_msg              := 'Operação realizada com sucesso.';
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
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/05/2015
  -- DESCRICAO: exclusao de regra de coenderecamento
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
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
    FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra de coendereçamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REGRA_COENDER_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  regra_coender_pkg.xml_gerar(p_regra_coender_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM usuario_coender
   WHERE regra_coender_id = p_regra_coender_id;
  DELETE FROM usuario_ender
   WHERE regra_coender_id = p_regra_coender_id;
  DELETE FROM regra_coender
   WHERE regra_coender_id = p_regra_coender_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_regra_coender_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'REGRA_COENDER',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_regra_coender_id,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 23/01/2017
  -- DESCRICAO: Subrotina que gera o xml da regra para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/09/2019  Novos atributos descricao e grupo
  ------------------------------------------------------------------------------------------
 (
  p_regra_coender_id IN regra_coender.regra_coender_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml        xmltype;
  v_xml_aux    xmltype;
  v_xml_aux_ue xmltype;
  v_xml_aux_uc xmltype;
  v_xml_doc    VARCHAR2(100);
  --
  CURSOR c_ue IS
   SELECT pe.apelido AS usuario,
          us.funcao
     FROM usuario_ender ue,
          pessoa        pe,
          usuario       us
    WHERE ue.regra_coender_id = p_regra_coender_id
      AND ue.usuario_id = pe.usuario_id
      AND ue.usuario_id = us.usuario_id;
  --
  CURSOR c_uc IS
   SELECT pe.apelido AS usuario,
          us.funcao
     FROM usuario_coender uc,
          pessoa          pe,
          usuario         us
    WHERE uc.regra_coender_id = p_regra_coender_id
      AND uc.usuario_id = pe.usuario_id
      AND uc.usuario_id = us.usuario_id;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("regra_coender_id", rc.regra_coender_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("descricao", rc.descricao),
                   xmlelement("grupo", gr.nome),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("produto_cliente", pc.nome),
                   xmlelement("tipo_job", tj.codigo),
                   xmlelement("ativo", rc.flag_ativo),
                   xmlelement("comentario", rc.comentario))
    INTO v_xml
    FROM regra_coender   rc,
         pessoa          cl,
         produto_cliente pc,
         tipo_job        tj,
         grupo           gr
   WHERE rc.regra_coender_id = p_regra_coender_id
     AND rc.cliente_id = cl.pessoa_id(+)
     AND rc.produto_cliente_id = pc.produto_cliente_id(+)
     AND rc.tipo_job_id = tj.tipo_job_id(+)
     AND rc.grupo_id = gr.grupo_id(+);
  --
  FOR r_ue IN c_ue
  LOOP
   SELECT xmlagg(xmlelement("usuario_ender",
                            xmlelement("usuario", r_ue.usuario),
                            xmlelement("funcao", r_ue.funcao)))
     INTO v_xml_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux_ue, v_xml_aux)
     INTO v_xml_aux_ue
     FROM dual;
  END LOOP;
  --
  FOR r_uc IN c_uc
  LOOP
   SELECT xmlagg(xmlelement("usuario_coender",
                            xmlelement("usuario", r_uc.usuario),
                            xmlelement("funcao", r_uc.funcao)))
     INTO v_xml_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux_uc, v_xml_aux)
     INTO v_xml_aux_uc
     FROM dual;
  END LOOP;
  --
  -- junta tudo debaixo de "regra_coender"
  SELECT xmlagg(xmlelement("regra_coender", v_xml, v_xml_aux_ue, v_xml_aux_uc))
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
END; -- REGRA_COENDER_PKG



/
