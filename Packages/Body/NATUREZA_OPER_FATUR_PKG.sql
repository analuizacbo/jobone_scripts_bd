--------------------------------------------------------
--  DDL for Package Body NATUREZA_OPER_FATUR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NATUREZA_OPER_FATUR_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/08/2011
  -- DESCRICAO: Inclusão de natureza de operacao para faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN natureza_oper_fatur.pessoa_id%TYPE,
  p_codigo            IN natureza_oper_fatur.codigo%TYPE,
  p_descricao         IN natureza_oper_fatur.descricao%TYPE,
  p_flag_padrao       IN natureza_oper_fatur.flag_padrao%TYPE,
  p_flag_bv           IN natureza_oper_fatur.flag_bv%TYPE,
  p_flag_servico      IN natureza_oper_fatur.flag_servico%TYPE,
  p_ordem             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_natureza_oper_fatur_id natureza_oper_fatur.natureza_oper_fatur_id%TYPE;
  v_nome                   pessoa.nome%TYPE;
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NATUREZA_OPER_FATUR_C',
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
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
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
  IF length(p_descricao) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bv) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag BV inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_servico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag produto inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE pessoa_id = p_pessoa_id
     AND TRIM(upper(codigo)) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe para essa empresa de faturamento.';
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
  SELECT seq_natureza_oper_fatur.nextval
    INTO v_natureza_oper_fatur_id
    FROM dual;
  --
  INSERT INTO natureza_oper_fatur
   (natureza_oper_fatur_id,
    pessoa_id,
    codigo,
    descricao,
    flag_padrao,
    flag_bv,
    flag_servico,
    ordem)
  VALUES
   (v_natureza_oper_fatur_id,
    p_pessoa_id,
    TRIM(p_codigo),
    TRIM(p_descricao),
    p_flag_padrao,
    p_flag_bv,
    p_flag_servico,
    to_number(p_ordem));
  --
  /*
    IF p_flag_bv = 'S' THEN
       -- apenas uma natureza associada a empresa de faturamento pode ser BV.
       -- desmarca as demais.
       UPDATE natureza_oper_fatur
          SET flag_bv = 'N'
        WHERE pessoa_id = p_pessoa_id
          AND natureza_oper_fatur_id <> v_natureza_oper_fatur_id;
    END IF;
  */
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas uma natureza associada a empresa de faturamento pode ser padrao.
   -- desmarca as demais.
   UPDATE natureza_oper_fatur
      SET flag_padrao = 'N'
    WHERE pessoa_id = p_pessoa_id
      AND natureza_oper_fatur_id <> v_natureza_oper_fatur_id;
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
  v_identif_objeto := TRIM(v_nome);
  v_compl_histor   := 'Inclusão de natureza de faturamento (' || TRIM(p_codigo) || ')';
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/08/2011
  -- DESCRICAO: Atualização de natureza de operacao para faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_natureza_oper_fatur_id IN natureza_oper_fatur.natureza_oper_fatur_id%TYPE,
  p_codigo                 IN natureza_oper_fatur.codigo%TYPE,
  p_descricao              IN natureza_oper_fatur.descricao%TYPE,
  p_flag_padrao            IN natureza_oper_fatur.flag_padrao%TYPE,
  p_flag_bv                IN natureza_oper_fatur.flag_bv%TYPE,
  p_flag_servico           IN natureza_oper_fatur.flag_servico%TYPE,
  p_ordem                  IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_pessoa_id      natureza_oper_fatur.pessoa_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_codigo         natureza_oper_fatur.codigo%TYPE;
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
    FROM natureza_oper_fatur na,
         pessoa              pe
   WHERE na.natureza_oper_fatur_id = p_natureza_oper_fatur_id
     AND na.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de operação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NATUREZA_OPER_FATUR_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT pessoa_id,
         codigo
    INTO v_pessoa_id,
         v_codigo
    FROM natureza_oper_fatur
   WHERE natureza_oper_fatur_id = p_natureza_oper_fatur_id;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = v_pessoa_id;
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
  IF length(p_descricao) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bv) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag BV inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_servico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag produto inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE pessoa_id = v_pessoa_id
     AND TRIM(upper(codigo)) = TRIM(upper(p_codigo))
     AND natureza_oper_fatur_id <> p_natureza_oper_fatur_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe para essa empresa de faturamento.';
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
  UPDATE natureza_oper_fatur
     SET codigo       = TRIM(p_codigo),
         descricao    = TRIM(p_descricao),
         flag_padrao  = p_flag_padrao,
         flag_bv      = p_flag_bv,
         flag_servico = p_flag_servico,
         ordem        = to_number(p_ordem)
   WHERE natureza_oper_fatur_id = p_natureza_oper_fatur_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas uma natureza associada a empresa de faturamento pode ser padrao.
   -- desmarca as demais.
   UPDATE natureza_oper_fatur
      SET flag_padrao = 'N'
    WHERE pessoa_id = v_pessoa_id
      AND natureza_oper_fatur_id <> p_natureza_oper_fatur_id;
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
  v_identif_objeto := TRIM(v_nome);
  v_compl_histor   := 'Alteração de natureza de faturamento (' || TRIM(v_codigo) || ')';
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/08/2011
  -- DESCRICAO: Exclusão de natureza de operacao para faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_natureza_oper_fatur_id IN natureza_oper_fatur.natureza_oper_fatur_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_pessoa_id      natureza_oper_fatur.pessoa_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_codigo         natureza_oper_fatur.codigo%TYPE;
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
    FROM natureza_oper_fatur na,
         pessoa              pe
   WHERE na.natureza_oper_fatur_id = p_natureza_oper_fatur_id
     AND na.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de operação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NATUREZA_OPER_FATUR_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT pessoa_id,
         codigo
    INTO v_pessoa_id,
         v_codigo
    FROM natureza_oper_fatur
   WHERE natureza_oper_fatur_id = p_natureza_oper_fatur_id;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = v_pessoa_id;
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
  DELETE FROM natureza_oper_fatur
   WHERE natureza_oper_fatur_id = p_natureza_oper_fatur_id;
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
  v_identif_objeto := TRIM(v_nome);
  v_compl_histor   := 'Exclusão de natureza de faturamento (' || TRIM(v_codigo) || ')';
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
 END excluir;
 --
--
END natureza_oper_fatur_pkg;



/
