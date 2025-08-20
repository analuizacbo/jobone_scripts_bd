--------------------------------------------------------
--  DDL for Package Body STATUS_AUX_OPORT_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "STATUS_AUX_OPORT_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/02/2019
  -- DESCRICAO: Inclusão de status auxiliar/estendido da oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/07/2022  Novo param flag_obriga_cenario
  -- Ana Luiza         17/11/2023  Novo param flag_obriga_preco_manual
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN empresa.empresa_id%TYPE,
  p_cod_status_pai           IN status_aux_oport.cod_status_pai%TYPE,
  p_nome                     IN status_aux_oport.nome%TYPE,
  p_ordem                    IN VARCHAR2,
  p_flag_obriga_cenario      IN VARCHAR2,
  p_flag_obriga_preco_manual IN VARCHAR2,
  p_flag_padrao              IN VARCHAR2,
  p_status_aux_oport_id      OUT status_aux_oport.status_aux_oport_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_status_aux_oport_id status_aux_oport.status_aux_oport_id%TYPE;
  v_ordem               status_aux_oport.ordem%TYPE;
  --
 BEGIN
  v_qt                  := 0;
  p_status_aux_oport_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'STATUS_AUX_OPORT_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_cod_status_pai) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status principal é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('status_oportunidade', p_cod_status_pai) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do status principal é inválido (' || p_cod_status_pai || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_ordem) IS NULL THEN
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
  IF flag_validar(p_flag_obriga_cenario) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga cenário inválido.';
   RAISE v_exception;
  END IF;
  --
  --ALCBO_171123
  IF flag_validar(p_flag_obriga_preco_manual) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga preço manual inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND cod_status_pai = p_cod_status_pai
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de status já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_status_aux_oport.nextval
    INTO v_status_aux_oport_id
    FROM dual;
  --
  INSERT INTO status_aux_oport
   (status_aux_oport_id,
    empresa_id,
    cod_status_pai,
    nome,
    ordem,
    flag_padrao,
    flag_ativo,
    flag_obriga_cenario,
    flag_obriga_preco_manual)
  VALUES
   (v_status_aux_oport_id,
    p_empresa_id,
    p_cod_status_pai,
    TRIM(p_nome),
    v_ordem,
    p_flag_padrao,
    'S',
    p_flag_obriga_cenario,
    p_flag_obriga_preco_manual);
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um pode ser padrao.
   UPDATE status_aux_oport
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = p_cod_status_pai
      AND status_aux_oport_id <> v_status_aux_oport_id;
  END IF;
  --
  COMMIT;
  p_status_aux_oport_id := v_status_aux_oport_id;
  p_erro_cod            := '00000';
  p_erro_msg            := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/02/2019
  -- DESCRICAO: Atualização de status auxiliar/estendido da oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/07/2022  Novo param flag_obriga_cenario
  -- Ana Luiza         17/11/2023  Novo param flag_obriga_preco_manual
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN empresa.empresa_id%TYPE,
  p_status_aux_oport_id      IN status_aux_oport.status_aux_oport_id%TYPE,
  p_nome                     IN status_aux_oport.nome%TYPE,
  p_ordem                    IN VARCHAR2,
  p_flag_obriga_cenario      IN VARCHAR2,
  p_flag_obriga_preco_manual IN VARCHAR2,
  p_flag_padrao              IN VARCHAR2,
  p_flag_ativo               IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_status_pai  status_aux_oport.cod_status_pai%TYPE;
  v_ordem           status_aux_oport.ordem%TYPE;
  v_nome_status_pai VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'STATUS_AUX_OPORT_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse status não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT cod_status_pai
    INTO v_cod_status_pai
    FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id;
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
  IF rtrim(p_ordem) IS NULL THEN
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
  IF flag_validar(p_flag_obriga_cenario) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga cenário inválido.';
   RAISE v_exception;
  END IF;
  --
  --ALCBO_171123
  IF flag_validar(p_flag_obriga_preco_manual) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga preço manual inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_ativo = 'N' AND p_flag_padrao = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido marcado como padrão não pode ficar inativo.';
   RAISE v_exception;
  END IF;
  --
  v_nome_status_pai := util_pkg.desc_retornar('status_oportunidade', v_cod_status_pai);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND cod_status_pai = v_cod_status_pai
     AND empresa_id = p_empresa_id
     AND status_aux_oport_id <> p_status_aux_oport_id;
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
  UPDATE status_aux_oport
     SET nome                     = TRIM(p_nome),
         ordem                    = v_ordem,
         flag_padrao              = p_flag_padrao,
         flag_ativo               = p_flag_ativo,
         flag_obriga_cenario      = p_flag_obriga_cenario,
         flag_obriga_preco_manual = p_flag_obriga_preco_manual
   WHERE status_aux_oport_id = p_status_aux_oport_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um pode ser padrao. Marca os demais como nao padrao.
   UPDATE status_aux_oport
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = v_cod_status_pai
      AND status_aux_oport_id <> p_status_aux_oport_id;
  ELSE
   -- verifica se sobrou outro status padrao.
   SELECT COUNT(*)
     INTO v_qt
     FROM status_aux_oport
    WHERE cod_status_pai = v_cod_status_pai
      AND empresa_id = p_empresa_id
      AND flag_padrao = 'S';
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deve existir um status estendido padrão para o status ' ||
                  v_nome_status_pai || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_flag_padrao = 'N' THEN
   -- verifica se sobrou outro status ativo.
   SELECT COUNT(*)
     INTO v_qt
     FROM status_aux_oport
    WHERE cod_status_pai = v_cod_status_pai
      AND empresa_id = p_empresa_id
      AND flag_ativo = 'S';
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deve existir pelo menos um status estendido ativo para o status ' ||
                  v_nome_status_pai || '.';
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/02/2019
  -- DESCRICAO: Exclusão de status auxiliar/estendido da oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_status_aux_oport_id IN status_aux_oport.status_aux_oport_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_flag_padrao     status_aux_oport.flag_padrao%TYPE;
  v_cod_status_pai  status_aux_oport.cod_status_pai%TYPE;
  v_nome_status_pai VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'STATUS_AUX_OPORT_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse status não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_padrao,
         cod_status_pai
    INTO v_flag_padrao,
         v_cod_status_pai
    FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id;
  --
  IF v_flag_padrao = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Outro status deve ser definido como padrão para que esse possa ser excluído.';
   RAISE v_exception;
  END IF;
  --
  v_nome_status_pai := util_pkg.desc_retornar('status_oportunidade', v_cod_status_pai);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE status_aux_oport_id = p_status_aux_oport_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem oportunidades associadas a esse status.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE cod_status_pai = v_cod_status_pai
     AND empresa_id = p_empresa_id
     AND flag_ativo = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Deve existir pelo menos um status estendido ativo para o status ' ||
                 v_nome_status_pai || '.';
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
END; -- STATUS_AUX_OPORT_PKG



/
