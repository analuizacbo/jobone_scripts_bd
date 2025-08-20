--------------------------------------------------------
--  DDL for Package Body LINK_DIRETO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "LINK_DIRETO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 01/07/2021
  -- DESCRICAO: Adiciona um link direto
  -- tipo_link: REL_CLI (relatorio de cliente;
  --            AVAL_OS (avaliacao de workflow);
  --            APROV_OS (aprovacao de workflow)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/09/2022  Novo parametro tipo_link; novo param ordem_servico_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN link_direto.empresa_id%TYPE,
  p_cliente_id        IN link_direto.cliente_id%TYPE,
  p_ordem_servico_id  IN link_direto.ordem_servico_id%TYPE,
  p_tipo_link         IN VARCHAR2,
  p_interface         IN VARCHAR2,
  p_link              IN VARCHAR2,
  p_cod_hash          IN VARCHAR2,
  p_link_direto_id    OUT link_direto.link_direto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_link_direto_id link_direto.link_direto_id%TYPE;
  v_data_validade  link_direto.data_validade%TYPE;
  v_num_dias       NUMBER(20);
  --
 BEGIN
  v_qt             := 0;
  p_link_direto_id := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa não existe (' || to_char(p_empresa_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_ordem_servico_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM ordem_servico
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse workflow não existe (' || to_char(p_ordem_servico_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_tipo_link) IS NULL OR p_tipo_link NOT IN ('REL_CLI', 'AVAL_OS', 'APROV_OS') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de link inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_interface) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Interface é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_interface) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Interface não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_link) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Link é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_link) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Link não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_hash) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Código Hash é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_hash) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Hash não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_link = 'REL_CLI' THEN
   v_num_dias := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                              'NUM_DIAS_VAL_LINKS_REL_CLI')),
                     0);
  ELSIF p_tipo_link = 'AVAL_OS' THEN
   v_num_dias := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                              'NUM_DIAS_VAL_LINKS_AVAL_OS')),
                     0);
  ELSE
   -- nao exipira
   v_num_dias := 100000;
  END IF;
  v_data_validade := SYSDATE + v_num_dias;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_link_direto.nextval
    INTO v_link_direto_id
    FROM dual;
  --
  INSERT INTO link_direto
   (link_direto_id,
    usuario_id,
    empresa_id,
    cliente_id,
    ordem_servico_id,
    data_geracao,
    data_validade,
    interface,
    link,
    tipo_link,
    cod_hash)
  VALUES
   (v_link_direto_id,
    p_usuario_sessao_id,
    p_empresa_id,
    TRIM(p_cliente_id),
    zvl(p_ordem_servico_id, NULL),
    SYSDATE,
    v_data_validade,
    TRIM(p_interface),
    TRIM(p_link),
    TRIM(p_tipo_link),
    TRIM(p_cod_hash));
  --
  COMMIT;
  p_link_direto_id := v_link_direto_id;
  p_erro_cod       := '00000';
  p_erro_msg       := 'Operação realizada com sucesso.';
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
END; -- LINK_DIRETO_PKG



/
