--------------------------------------------------------
--  DDL for Package Body PRODUTO_CLIENTE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PRODUTO_CLIENTE_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2007
  -- DESCRICAO: Inclusão de PRODUTO_CLIENTE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            02/01/2017  Novo parametro flag_commit para uso como subrotina.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_pessoa_id          IN produto_cliente.pessoa_id%TYPE,
  p_nome               IN produto_cliente.nome%TYPE,
  p_produto_cliente_id OUT produto_cliente.produto_cliente_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_produto_cliente_id produto_cliente.produto_cliente_id%TYPE;
  v_cliente            pessoa.nome%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_prodcli        VARCHAR2(100);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_prodcli        := empresa_pkg.parametro_retornar(p_empresa_id,
                                                         'LABEL_PRODCLI_SINGULAR');
  p_produto_cliente_id := 0;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_C',
                                p_pessoa_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_cliente
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE pessoa_id = p_pessoa_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de ' || v_lbl_prodcli || ' já existe para esse cliente.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_produto_cliente.nextval
    INTO v_produto_cliente_id
    FROM dual;
  --
  INSERT INTO produto_cliente
   (produto_cliente_id,
    pessoa_id,
    nome,
    flag_ativo)
  VALUES
   (v_produto_cliente_id,
    p_pessoa_id,
    TRIM(p_nome),
    'S');
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('PRODUTO_CLIENTE_ADICIONAR',
                           p_empresa_id,
                           v_produto_cliente_id,
                           NULL,
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
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_cliente;
  v_compl_histor   := 'Inclusão de ' || v_lbl_prodcli || ': ' || p_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
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
  --
  p_produto_cliente_id := v_produto_cliente_id;
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2007
  -- DESCRICAO: Atualização de PRODUTO_CLIENTE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_produto_cliente_id IN produto_cliente.produto_cliente_id%TYPE,
  p_nome               IN produto_cliente.nome%TYPE,
  p_flag_ativo         IN produto_cliente.flag_ativo%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_pessoa_id      pessoa.pessoa_id%TYPE;
  v_cliente        pessoa.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_prodcli    VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt          := 0;
  v_lbl_prodcli := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente pc,
         pessoa          pe
   WHERE pc.produto_cliente_id = p_produto_cliente_id
     AND pc.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.pessoa_id,
         pe.nome
    INTO v_pessoa_id,
         v_cliente
    FROM produto_cliente pc,
         pessoa          pe
   WHERE pc.produto_cliente_id = p_produto_cliente_id
     AND pc.pessoa_id = pe.pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_C',
                                v_pessoa_id,
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE pessoa_id = v_pessoa_id
     AND produto_cliente_id <> p_produto_cliente_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de ' || v_lbl_prodcli || ' já existe para esse cliente.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE produto_cliente
     SET nome       = TRIM(p_nome),
         flag_ativo = p_flag_ativo
   WHERE produto_cliente_id = p_produto_cliente_id;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('PRODUTO_CLIENTE_ATUALIZAR',
                           p_empresa_id,
                           p_produto_cliente_id,
                           NULL,
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
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_cliente;
  v_compl_histor   := 'Alteração de ' || v_lbl_prodcli || ': ' || p_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_pessoa_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2007
  -- DESCRICAO: Exclusão de PRODUTO_CLIENTE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/06/2015  Consistencia de faturamento
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            11/03/2019  Consistencia de oportunidade.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_produto_cliente_id IN produto_cliente.produto_cliente_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           produto_cliente.nome%TYPE;
  v_pessoa_id      pessoa.pessoa_id%TYPE;
  v_cliente        pessoa.nome%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  v_lbl_prodcli    VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt          := 0;
  v_lbl_jobs    := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_prodcli := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente pc,
         pessoa          pe
   WHERE pc.produto_cliente_id = p_produto_cliente_id
     AND pc.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.pessoa_id,
         pe.nome,
         pc.nome
    INTO v_pessoa_id,
         v_cliente,
         v_nome
    FROM produto_cliente pc,
         pessoa          pe
   WHERE pc.produto_cliente_id = p_produto_cliente_id
     AND pc.pessoa_id = pe.pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_C',
                                v_pessoa_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
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
    FROM job
   WHERE produto_cliente_id = p_produto_cliente_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse ' || v_lbl_prodcli || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE produto_cliente_id = p_produto_cliente_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de horas associados a esse ' || v_lbl_prodcli || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE produto_cliente_id = p_produto_cliente_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a esse ' || v_lbl_prodcli || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE produto_cliente_id = p_produto_cliente_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a esse ' || v_lbl_prodcli || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE produto_cliente_id = p_produto_cliente_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de endereçamento associadas a esse ' || v_lbl_prodcli || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('PRODUTO_CLIENTE_EXCLUIR',
                           p_empresa_id,
                           p_produto_cliente_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM produto_cliente
   WHERE produto_cliente_id = p_produto_cliente_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_cliente;
  v_compl_histor   := 'Exclusão de ' || v_lbl_prodcli || ': ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_pessoa_id,
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
 END; -- excluir
--
--
END; -- PRODUTO_CLIENTE_PKG



/
