--------------------------------------------------------
--  DDL for Package Body SISTEMA_EXTERNO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SISTEMA_EXTERNO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Inclusão de SISTEMA_EXTERNO como inativo (soh pode ter 1 ativo
  --  por tipo de sistema).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_codigo             IN sistema_externo.codigo%TYPE,
  p_nome               IN sistema_externo.nome%TYPE,
  p_tipo_integracao_id IN sistema_externo.tipo_integracao_id%TYPE,
  p_tipo_sistema       IN sistema_externo.tipo_sistema%TYPE,
  p_sistema_externo_id OUT sistema_externo.sistema_externo_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt                 := 0;
  p_sistema_externo_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
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
  IF TRIM(p_tipo_sistema) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de sistema obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_sistema) NOT IN ('FIN') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de sistema inválido (' || p_tipo_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_integracao
   WHERE tipo_integracao_id = nvl(p_tipo_integracao_id, 0);
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de integração inválido.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE upper(codigo) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_sistema_externo.nextval
    INTO v_sistema_externo_id
    FROM dual;
  --
  INSERT INTO sistema_externo
   (sistema_externo_id,
    codigo,
    nome,
    tipo_sistema,
    tipo_integracao_id,
    flag_ativo)
  VALUES
   (v_sistema_externo_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    TRIM(p_tipo_sistema),
    p_tipo_integracao_id,
    'N');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sistema_externo_pkg.xml_gerar(v_sistema_externo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo)) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_sistema_externo_id,
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
  p_sistema_externo_id := v_sistema_externo_id;
  p_erro_cod           := '00000';
  p_erro_msg           := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Atualização de SISTEMA_EXTERNO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_codigo             IN sistema_externo.codigo%TYPE,
  p_nome               IN sistema_externo.nome%TYPE,
  p_tipo_integracao_id IN sistema_externo.tipo_integracao_id%TYPE,
  p_tipo_sistema       IN sistema_externo.tipo_sistema%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_antes      CLOB;
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
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse sistema externo não existe.';
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
  IF TRIM(p_tipo_sistema) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de sistema obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_sistema) NOT IN ('FIN') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de sistema inválido (' || p_tipo_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_integracao
   WHERE tipo_integracao_id = nvl(p_tipo_integracao_id, 0);
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de integração inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND sistema_externo_id <> p_sistema_externo_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND sistema_externo_id <> p_sistema_externo_id;
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
  sistema_externo_pkg.xml_gerar(p_sistema_externo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE sistema_externo
     SET codigo             = TRIM(upper(p_codigo)),
         nome               = TRIM(p_nome),
         tipo_sistema       = TRIM(p_tipo_sistema),
         tipo_integracao_id = p_tipo_integracao_id
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sistema_externo_pkg.xml_gerar(p_sistema_externo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo)) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_sistema_externo_id,
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
 PROCEDURE ativo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Atualização do flag_ativo do SISTEMA_EXTERNO (soh pode ter 1 ativo
  --  por tipo de sistema).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_flag_ativo         IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_codigo         sistema_externo.codigo%TYPE;
  v_nome           sistema_externo.nome%TYPE;
  v_tipo_sistema   sistema_externo.tipo_sistema%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse sistema externo não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         codigo,
         tipo_sistema
    INTO v_nome,
         v_codigo,
         v_tipo_sistema
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  sistema_externo_pkg.xml_gerar(p_sistema_externo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_ativo = 'S' THEN
   -- inativa todos os sistemas do mesmo tipo pois soh pode
   -- ter um ativo por tipo de sistema.
   UPDATE sistema_externo
      SET flag_ativo = 'N'
    WHERE tipo_sistema = v_tipo_sistema;
  END IF;
  --
  UPDATE sistema_externo
     SET flag_ativo = TRIM(p_flag_ativo)
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sistema_externo_pkg.xml_gerar(p_sistema_externo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo)) || ' - ' || TRIM(v_nome);
  v_compl_histor   := 'Alteração de flag ativo: ' || p_flag_ativo;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_sistema_externo_id,
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
 END ativo_atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Exclusão de SISTEMA_EXTERNO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         sistema_externo.codigo%TYPE;
  v_nome           sistema_externo.nome%TYPE;
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
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse sistema externo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sistema_externo_pkg.xml_gerar(p_sistema_externo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM empresa_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM pessoa_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM sist_ext_ponto_int
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id;
  DELETE FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo || ' - ' || v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_sistema_externo_id,
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
 PROCEDURE ponto_integracao_ligar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Liga ponto de integracao do SISTEMA_EXTERNO numa determinada empresa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
  p_ponto_integracao_id IN ponto_integracao.ponto_integracao_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo_sis     sistema_externo.codigo%TYPE;
  v_nome_sis       sistema_externo.nome%TYPE;
  v_tipo_sistema   sistema_externo.tipo_sistema%TYPE;
  v_codigo_pto     ponto_integracao.codigo%TYPE;
  v_nome_pto       ponto_integracao.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse sistema externo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ponto_integracao
   WHERE ponto_integracao_id = p_ponto_integracao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ponto de integração não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT nome,
         codigo,
         tipo_sistema
    INTO v_nome_sis,
         v_codigo_sis,
         v_tipo_sistema
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  SELECT nome,
         codigo
    INTO v_nome_pto,
         v_codigo_pto
    FROM ponto_integracao
   WHERE ponto_integracao_id = p_ponto_integracao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sist_ext_ponto_int
   WHERE sistema_externo_id = p_sistema_externo_id
     AND empresa_id = p_empresa_id
     AND ponto_integracao_id = p_ponto_integracao_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ponto de integração já está ligado nessa empresa.';
   RAISE v_exception;
  END IF;
  --
  /* nao precisa mais consistir pois apenas 1 sistema externo pode estar ativo
    SELECT COUNT(*)
      INTO v_qt
      FROM sist_ext_ponto_int sp,
           sistema_externo si
     WHERE sp.sistema_externo_id = si.sistema_externo_id
       AND si.tipo_sistema = v_tipo_sistema
       AND sp.empresa_id = p_empresa_id
       AND sp.ponto_integracao_id = p_ponto_integracao_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Esse ponto de integração já está ligado em outro sistema externo do mesmo tipo.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO sist_ext_ponto_int
   (sistema_externo_id,
    ponto_integracao_id,
    empresa_id)
  VALUES
   (p_sistema_externo_id,
    p_ponto_integracao_id,
    p_empresa_id);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo_sis)) || ' - ' || TRIM(v_nome_sis);
  v_compl_histor   := 'Ponto de integração ligado: ' || TRIM(upper(v_codigo_pto)) || ' - ' ||
                      TRIM(v_nome_pto);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_sistema_externo_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END ponto_integracao_ligar;
 --
 --
 PROCEDURE ponto_integracao_desligar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/09/2022
  -- DESCRICAO: Desliga ponto de integracao do SISTEMA_EXTERNO numa determinada empresa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
  p_ponto_integracao_id IN ponto_integracao.ponto_integracao_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo_sis     sistema_externo.codigo%TYPE;
  v_nome_sis       sistema_externo.nome%TYPE;
  v_tipo_sistema   sistema_externo.tipo_sistema%TYPE;
  v_codigo_pto     ponto_integracao.codigo%TYPE;
  v_nome_pto       ponto_integracao.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE (flag_admin_sistema = 'S' OR flag_admin = 'S')
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse sistema externo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ponto_integracao
   WHERE ponto_integracao_id = p_ponto_integracao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ponto de integração não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT nome,
         codigo,
         tipo_sistema
    INTO v_nome_sis,
         v_codigo_sis,
         v_tipo_sistema
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  SELECT nome,
         codigo
    INTO v_nome_pto,
         v_codigo_pto
    FROM ponto_integracao
   WHERE ponto_integracao_id = p_ponto_integracao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sist_ext_ponto_int
   WHERE sistema_externo_id = p_sistema_externo_id
     AND empresa_id = p_empresa_id
     AND ponto_integracao_id = p_ponto_integracao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ponto de integração não está ligado nessa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM sist_ext_ponto_int
   WHERE sistema_externo_id = p_sistema_externo_id
     AND ponto_integracao_id = p_ponto_integracao_id
     AND empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo_sis)) || ' - ' || TRIM(v_nome_sis);
  v_compl_histor   := 'Ponto de integração desligado: ' || TRIM(upper(v_codigo_pto)) || ' - ' ||
                      TRIM(v_nome_pto);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SISTEMA_EXTERNO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_sistema_externo_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END ponto_integracao_desligar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/02/2017
  -- DESCRICAO: Subrotina que gera o xml do sistema externo para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_xml                OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
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
  SELECT xmlconcat(xmlelement("sistema_externo_id", si.sistema_externo_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo_sistema", si.codigo),
                   xmlelement("nome_sistema", si.nome),
                   xmlelement("tipo_sistema",
                              decode(si.tipo_sistema, 'FIN', 'Financeiro', 'ND')),
                   xmlelement("tipo_integracao", ti.codigo),
                   xmlelement("ativo", si.flag_ativo))
    INTO v_xml
    FROM sistema_externo si,
         tipo_integracao ti
   WHERE si.sistema_externo_id = p_sistema_externo_id
     AND si.tipo_integracao_id = ti.tipo_integracao_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_documento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("sistema_externo", v_xml))
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
END sistema_externo_pkg;



/
