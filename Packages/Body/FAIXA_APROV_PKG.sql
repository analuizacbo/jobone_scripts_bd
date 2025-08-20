--------------------------------------------------------
--  DDL for Package Body FAIXA_APROV_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FAIXA_APROV_PKG" IS
 --
 PROCEDURE ao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/12/2013
  -- DESCRICAO: Inclusão de FAIXA_APROV de carta_acordo/AO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/01/2015  Novos flags pata itens de A e BC.
  -- Silvia            24/06/2015  Novo parametro cliente_id
  -- Silvia            13/11/2015  Novo parametro fornec_homolog
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  -- Silvia            26/09/2016  Novo parametro p_faixa_aprov_ori_id. Qdo preenchido,
  --                               indica a faixa a ser usada como base p/ a nova (duplicar).
  -- Silvia            16/11/2017  Ativacao/inativacao da faixa.
  -- Silvia            08/06/2018  Novo parametro fornec_interno
  -- Silvia            04/03/2020  Novos parametros de resultado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faixa_aprov_ori_id IN faixa_aprov.faixa_aprov_id%TYPE,
  p_valor_de           IN VARCHAR2,
  p_valor_ate          IN VARCHAR2,
  p_cliente_id         IN faixa_aprov_ao.cliente_id%TYPE,
  p_flag_itens_a       IN VARCHAR2,
  p_flag_itens_bc      IN VARCHAR2,
  p_fornec_homolog     IN VARCHAR2,
  p_fornec_interno     IN VARCHAR2,
  p_resultado_de       IN VARCHAR2,
  p_resultado_ate      IN VARCHAR2,
  p_faixa_aprov_id     OUT faixa_aprov.faixa_aprov_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_faixa_aprov_id faixa_aprov.faixa_aprov_id%TYPE;
  v_valor_de       faixa_aprov_ao.valor_de%TYPE;
  v_valor_ate      faixa_aprov_ao.valor_ate%TYPE;
  v_resultado_de   faixa_aprov_ao.resultado_de%TYPE;
  v_resultado_ate  faixa_aprov_ao.resultado_ate%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
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
                                'FAIXA_APROV_AO_C',
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
  IF rtrim(p_valor_de) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor DE é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_de) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor DE inválido (' || p_valor_de || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_de := nvl(moeda_converter(p_valor_de), 0);
  --
  IF moeda_validar(p_valor_ate) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor ATÉ inválido (' || p_valor_ate || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_ate := moeda_converter(p_valor_ate);
  --
  IF v_valor_de > v_valor_ate THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor DE não pode ser maior que o valor ATÉ.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_itens_a) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag para itens de A inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_itens_bc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag para itens de B e C inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_itens_a = 'N' AND p_flag_itens_bc = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Algum tipo de item deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_fornec_homolog) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor homologado não informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_fornec_homolog NOT IN ('S', 'N', 'A') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor homologado inválido (' || p_fornec_homolog || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_fornec_interno) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor interno não informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_fornec_interno NOT IN ('S', 'N', 'A') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor interno inválido (' || p_fornec_interno || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_resultado_de) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado DE inválido (' || p_resultado_de || ').';
   RAISE v_exception;
  END IF;
  --
  v_resultado_de := taxa_converter(p_resultado_de);
  --
  IF v_resultado_de IS NOT NULL AND v_resultado_de NOT BETWEEN 0 AND 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado DE inválido (' || p_resultado_de || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_resultado_ate) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado ATÉ inválido (' || p_resultado_ate || ').';
   RAISE v_exception;
  END IF;
  --
  v_resultado_ate := taxa_converter(p_resultado_ate);
  --
  IF v_resultado_ate IS NOT NULL AND v_resultado_ate NOT BETWEEN 0 AND 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado ATÉ inválido (' || v_resultado_ate || ').';
   RAISE v_exception;
  END IF;
  --
  IF (v_resultado_de IS NULL AND v_resultado_ate IS NOT NULL) OR
     (v_resultado_de IS NOT NULL AND v_resultado_ate IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Resultado não pode ser informado parcialmente.';
   RAISE v_exception;
  END IF;
  --
  IF v_resultado_de > v_resultado_ate THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Resultado DE não pode ser maior que o Resultado ATÉ.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_faixa_aprov.nextval
    INTO v_faixa_aprov_id
    FROM dual;
  --
  INSERT INTO faixa_aprov
   (faixa_aprov_id,
    empresa_id,
    tipo_faixa,
    flag_sequencial,
    flag_ativo)
  VALUES
   (v_faixa_aprov_id,
    p_empresa_id,
    'AO',
    'S',
    'N');
  --
  INSERT INTO faixa_aprov_ao
   (faixa_aprov_id,
    cliente_id,
    valor_de,
    valor_ate,
    flag_itens_a,
    flag_itens_bc,
    fornec_homolog,
    fornec_interno,
    resultado_de,
    resultado_ate)
  VALUES
   (v_faixa_aprov_id,
    zvl(p_cliente_id, NULL),
    v_valor_de,
    v_valor_ate,
    TRIM(p_flag_itens_a),
    TRIM(p_flag_itens_bc),
    TRIM(p_fornec_homolog),
    TRIM(p_fornec_interno),
    v_resultado_de,
    v_resultado_ate);
  --
  IF nvl(p_faixa_aprov_ori_id, 0) > 0 THEN
   -- copia os papeis da faixa de origem
   INSERT INTO faixa_aprov_papel
    (faixa_aprov_id,
     papel_id,
     seq_aprov)
    SELECT v_faixa_aprov_id,
           papel_id,
           seq_aprov
      FROM faixa_aprov_papel
     WHERE faixa_aprov_id = p_faixa_aprov_ori_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(v_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_AO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_faixa_aprov_id,
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
  p_faixa_aprov_id := v_faixa_aprov_id;
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
 END ao_adicionar;
 --
 --
 PROCEDURE ao_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/12/2013
  -- DESCRICAO: Atualização de FAIXA_APROV
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/01/2015  Novos flags pata itens de A e BC.
  -- Silvia            24/06/2015  Novo parametro cliente_id
  -- Silvia            13/11/2015  Novo parametro fornec_homolog
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  -- Silvia            16/11/2017  Ativacao/inativacao da faixa.
  -- Silvia            08/06/2018  Novo parametro fornec_interno
  -- Silvia            04/03/2020  Novos parametros de resultado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_valor_de          IN VARCHAR2,
  p_valor_ate         IN VARCHAR2,
  p_cliente_id        IN faixa_aprov_ao.cliente_id%TYPE,
  p_flag_itens_a      IN VARCHAR2,
  p_flag_itens_bc     IN VARCHAR2,
  p_fornec_homolog    IN VARCHAR2,
  p_fornec_interno    IN VARCHAR2,
  p_resultado_de      IN VARCHAR2,
  p_resultado_ate     IN VARCHAR2,
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
  v_valor_de       faixa_aprov_ao.valor_de%TYPE;
  v_valor_ate      faixa_aprov_ao.valor_ate%TYPE;
  v_resultado_de   faixa_aprov_ao.resultado_de%TYPE;
  v_resultado_ate  faixa_aprov_ao.resultado_ate%TYPE;
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
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'FAIXA_APROV_AO_C',
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
  IF rtrim(p_valor_de) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor DE é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_de) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor DE inválido (' || p_valor_de || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_de := nvl(moeda_converter(p_valor_de), 0);
  --
  IF moeda_validar(p_valor_ate) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor ATÉ inválido (' || p_valor_ate || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_ate := moeda_converter(p_valor_ate);
  --
  IF v_valor_de > v_valor_ate THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor DE não pode ser maior que o valor ATÉ.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_itens_a) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag para itens de A inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_itens_bc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag para itens de B e C inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_itens_a = 'N' AND p_flag_itens_bc = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Algum tipo de item deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_fornec_homolog) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor homologado não informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_fornec_homolog NOT IN ('S', 'N', 'A') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor homologado inválido (' || p_fornec_homolog || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_fornec_interno) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor interno não informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_fornec_interno NOT IN ('S', 'N', 'A') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedor interno inválido (' || p_fornec_interno || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_resultado_de) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado DE inválido (' || p_resultado_de || ').';
   RAISE v_exception;
  END IF;
  --
  v_resultado_de := taxa_converter(p_resultado_de);
  --
  IF v_resultado_de IS NOT NULL AND v_resultado_de NOT BETWEEN 0 AND 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado DE inválido (' || p_resultado_de || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_resultado_ate) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado ATÉ inválido (' || p_resultado_ate || ').';
   RAISE v_exception;
  END IF;
  --
  v_resultado_ate := taxa_converter(p_resultado_ate);
  --
  IF v_resultado_ate IS NOT NULL AND v_resultado_ate NOT BETWEEN 0 AND 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Resultado ATÉ inválido (' || v_resultado_ate || ').';
   RAISE v_exception;
  END IF;
  --
  IF (v_resultado_de IS NULL AND v_resultado_ate IS NOT NULL) OR
     (v_resultado_de IS NOT NULL AND v_resultado_ate IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Resultado não pode ser informado parcialmente.';
   RAISE v_exception;
  END IF;
  --
  IF v_resultado_de > v_resultado_ate THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Resultado DE não pode ser maior que o Resultado ATÉ.';
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
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faixa_aprov
     SET flag_ativo = TRIM(p_flag_ativo),
         comentario = TRIM(p_comentario)
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  UPDATE faixa_aprov_ao
     SET valor_de       = v_valor_de,
         valor_ate      = v_valor_ate,
         flag_itens_a   = TRIM(p_flag_itens_a),
         flag_itens_bc  = TRIM(p_flag_itens_bc),
         fornec_homolog = TRIM(p_fornec_homolog),
         fornec_interno = TRIM(p_fornec_interno),
         cliente_id     = zvl(p_cliente_id, NULL),
         resultado_de   = v_resultado_de,
         resultado_ate  = v_resultado_ate
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_AO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 END ao_atualizar;
 --
 --
 PROCEDURE os_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/03/2016
  -- DESCRICAO: Inclusão de FAIXA_APROV de ordem_servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/05/2016  Novo parametro cliente_id
  -- Silvia            26/09/2016  Novo parametro p_faixa_aprov_ori_id. Qdo preenchido,
  --                               indica a faixa a ser usada como base p/ a nova (duplicar).
  -- Silvia            16/11/2017  Ativacao/inativacao da faixa.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faixa_aprov_ori_id IN faixa_aprov.faixa_aprov_id%TYPE,
  p_cliente_id         IN faixa_aprov_os.cliente_id%TYPE,
  p_tipo_job_id        IN faixa_aprov_os.tipo_job_id%TYPE,
  p_complex_job        IN VARCHAR2,
  p_flag_aprov_est     IN VARCHAR2,
  p_flag_aprov_exe     IN VARCHAR2,
  p_faixa_aprov_id     OUT faixa_aprov.faixa_aprov_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_faixa_aprov_id faixa_aprov.faixa_aprov_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'FAIXA_APROV_OS_C',
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
  IF nvl(p_tipo_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_job
    WHERE tipo_job_id = p_tipo_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de ' || v_lbl_job ||
                  ' não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_complex_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade não informada.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || p_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_aprov_est) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação da estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_aprov_exe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação da execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_aprov_est = 'N' AND p_flag_aprov_exe = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pelo menos um tipo de aprovação deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_faixa_aprov.nextval
    INTO v_faixa_aprov_id
    FROM dual;
  --
  INSERT INTO faixa_aprov
   (faixa_aprov_id,
    empresa_id,
    tipo_faixa,
    flag_sequencial,
    flag_ativo)
  VALUES
   (v_faixa_aprov_id,
    p_empresa_id,
    'OS',
    'S',
    'N');
  --
  INSERT INTO faixa_aprov_os
   (faixa_aprov_id,
    tipo_job_id,
    complex_job,
    flag_aprov_est,
    flag_aprov_exe,
    cliente_id)
  VALUES
   (v_faixa_aprov_id,
    zvl(p_tipo_job_id, NULL),
    TRIM(p_complex_job),
    TRIM(p_flag_aprov_est),
    TRIM(p_flag_aprov_exe),
    zvl(p_cliente_id, NULL));
  --
  IF nvl(p_faixa_aprov_ori_id, 0) > 0 THEN
   -- copia os papeis da faixa de origem
   INSERT INTO faixa_aprov_papel
    (faixa_aprov_id,
     papel_id,
     seq_aprov)
    SELECT v_faixa_aprov_id,
           papel_id,
           seq_aprov
      FROM faixa_aprov_papel
     WHERE faixa_aprov_id = p_faixa_aprov_ori_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(v_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_OS',
                   'INCLUIR',
                   v_identif_objeto,
                   v_faixa_aprov_id,
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
  p_faixa_aprov_id := v_faixa_aprov_id;
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
 END os_adicionar;
 --
 --
 PROCEDURE os_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/03/2016
  -- DESCRICAO: Atualização de FAIXA_APROV de ordem_servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/05/2016  Novo parametro cliente_id
  -- Silvia            16/11/2017  Ativacao/inativacao da faixa.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_cliente_id        IN faixa_aprov_os.cliente_id%TYPE,
  p_tipo_job_id       IN faixa_aprov_os.tipo_job_id%TYPE,
  p_complex_job       IN VARCHAR2,
  p_flag_aprov_est    IN VARCHAR2,
  p_flag_aprov_exe    IN VARCHAR2,
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
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'FAIXA_APROV_OS_C',
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
  IF nvl(p_tipo_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_job
    WHERE tipo_job_id = p_tipo_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_complex_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade não informada.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || p_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_aprov_est) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação da estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_aprov_exe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação da execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_aprov_est = 'N' AND p_flag_aprov_exe = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pelo menos um tipo de aprovação deve ser informado.';
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
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faixa_aprov
     SET flag_ativo = TRIM(p_flag_ativo),
         comentario = TRIM(p_comentario)
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  UPDATE faixa_aprov_os
     SET tipo_job_id    = zvl(p_tipo_job_id, NULL),
         complex_job    = TRIM(p_complex_job),
         flag_aprov_est = TRIM(p_flag_aprov_est),
         flag_aprov_exe = TRIM(p_flag_aprov_exe),
         cliente_id     = zvl(p_cliente_id, NULL)
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_OS',
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 END os_atualizar;
 --
 --
 PROCEDURE flag_ativo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/11/2017
  -- DESCRICAO: Atualização do flag_ativo de FAIXA_APROV de ordem_servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
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
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'FAIXA_APROV_OS_C',
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
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faixa_aprov
     SET flag_ativo = TRIM(p_flag_ativo),
         comentario = TRIM(p_comentario)
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := 'Ativação/inativação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_OS',
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 --
 PROCEDURE ec_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/05/2022
  -- DESCRICAO: Inclusão de FAIXA_APROV de estimativa de custos/EC
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    OUT faixa_aprov.faixa_aprov_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_faixa_aprov_id faixa_aprov.faixa_aprov_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
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
                                'FAIXA_APROV_EC_C',
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
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_faixa_aprov.nextval
    INTO v_faixa_aprov_id
    FROM dual;
  --
  INSERT INTO faixa_aprov
   (faixa_aprov_id,
    empresa_id,
    tipo_faixa,
    flag_sequencial,
    flag_ativo)
  VALUES
   (v_faixa_aprov_id,
    p_empresa_id,
    'EC',
    'S',
    'S');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(v_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FAIXA_APROV_EC',
                   'INCLUIR',
                   v_identif_objeto,
                   v_faixa_aprov_id,
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
  p_faixa_aprov_id := v_faixa_aprov_id;
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
 END ec_adicionar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/12/2013
  -- DESCRICAO: Exclusão de FAIXA_APROV
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_tipo_faixa     faixa_aprov.tipo_faixa%TYPE;
  v_cod_objeto     tipo_objeto.codigo%TYPE;
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
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_faixa
    INTO v_tipo_faixa
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  IF v_tipo_faixa = 'AO' THEN
   v_cod_objeto := 'FAIXA_APROV_AO';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_AO_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'OS' THEN
   v_cod_objeto := 'FAIXA_APROV_OS';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_OS_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'EC' THEN
   v_cod_objeto := 'FAIXA_APROV_EC';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_EC_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM faixa_aprov_papel
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  IF v_tipo_faixa = 'AO' THEN
   DELETE FROM faixa_aprov_ao
    WHERE faixa_aprov_id = p_faixa_aprov_id;
  ELSIF v_tipo_faixa = 'OS' THEN
   DELETE FROM faixa_aprov_os
    WHERE faixa_aprov_id = p_faixa_aprov_id;
  END IF;
  --
  DELETE FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   v_cod_objeto,
                   'EXCLUIR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 PROCEDURE papel_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/12/2013
  -- DESCRICAO: Associa papel a uma determinada faixa de aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/01/2015  Novo atributo seq_aprov.
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  -- Silvia            26/09/2016  Inclusao do papel no final ao inves de no comeco.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_tipo_faixa     faixa_aprov.tipo_faixa%TYPE;
  v_seq_aprov_max  faixa_aprov_papel.seq_aprov%TYPE;
  v_cod_objeto     tipo_objeto.codigo%TYPE;
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
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_faixa
    INTO v_tipo_faixa
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  IF v_tipo_faixa = 'AO' THEN
   v_cod_objeto := 'FAIXA_APROV_AO';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_AO_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'OS' THEN
   v_cod_objeto := 'FAIXA_APROV_OS';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_OS_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'EC' THEN
   v_cod_objeto := 'FAIXA_APROV_EC';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_EC_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = nvl(p_papel_id, 0)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa (papel_id=' ||
                 to_char(p_papel_id) || ', empresa_id=' || to_char(p_empresa_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(MAX(seq_aprov), 0)
    INTO v_seq_aprov_max
    FROM faixa_aprov_papel
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_seq_aprov_max := v_seq_aprov_max + 1;
  --
  INSERT INTO faixa_aprov_papel
   (faixa_aprov_id,
    papel_id,
    seq_aprov)
  VALUES
   (p_faixa_aprov_id,
    p_papel_id,
    v_seq_aprov_max);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := 'Inclusão de papel';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   v_cod_objeto,
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 END papel_adicionar;
 --
 --
 PROCEDURE papel_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/12/2013
  -- DESCRICAO: Desassocia papel de uma determinada faixa de aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  -- Silvia            26/09/2016  flag_commit
  -- Silvia            30/08/2017  Ajuste em exclusao massiva (mesmo papel em seq diferentes)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_seq_aprov         IN faixa_aprov_papel.seq_aprov%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_tipo_faixa     faixa_aprov.tipo_faixa%TYPE;
  v_seq_aprov_ant  faixa_aprov_papel.seq_aprov%TYPE;
  v_seq_aprov_ren  faixa_aprov_papel.seq_aprov%TYPE;
  v_cod_objeto     tipo_objeto.codigo%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_nome_papel     papel.nome%TYPE;
  v_seq_aprov_aux  faixa_aprov_papel.seq_aprov%TYPE;
  --
  CURSOR c_fa IS
   SELECT seq_aprov
     FROM faixa_aprov_papel
    WHERE faixa_aprov_id = p_faixa_aprov_id
    ORDER BY seq_aprov;
  --
  CURSOR c_fa2 IS
   SELECT ROWID,
          seq_aprov
     FROM faixa_aprov_papel
    WHERE faixa_aprov_id = p_faixa_aprov_id
      AND seq_aprov >= v_seq_aprov_ren
    ORDER BY seq_aprov;
  --
 BEGIN
  v_qt := 0;
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
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_faixa
    INTO v_tipo_faixa
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  IF v_tipo_faixa = 'AO' THEN
   v_cod_objeto := 'FAIXA_APROV_AO';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_AO_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'OS' THEN
   v_cod_objeto := 'FAIXA_APROV_OS';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_OS_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'EC' THEN
   v_cod_objeto := 'FAIXA_APROV_EC';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_EC_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = nvl(p_papel_id, 0)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_papel
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  v_seq_aprov_aux := p_seq_aprov;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_papel
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND papel_id = p_papel_id
     AND seq_aprov = p_seq_aprov;
  --
  IF v_qt = 0 THEN
   IF p_flag_commit = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse papel (' || to_char(p_papel_id) || ' - ' || v_nome_papel ||
                  ') não está associado a essa faixa de aprovação (' ||
                  to_char(p_faixa_aprov_id) || ') nessa sequência (' || to_char(p_seq_aprov) || ').';
    RAISE v_exception;
   ELSE
    -- pode nao ter achado por causa da renumeracao da exclusao em massa
    SELECT MAX(seq_aprov)
      INTO v_seq_aprov_aux
      FROM faixa_aprov_papel
     WHERE faixa_aprov_id = p_faixa_aprov_id
       AND papel_id = p_papel_id
       AND seq_aprov <= p_seq_aprov;
    --
    IF v_seq_aprov_aux IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse papel (' || to_char(p_papel_id) || ' - ' || v_nome_papel ||
                   ') não está associado a essa faixa de aprovação (' ||
                   to_char(p_faixa_aprov_id) || ') nessa sequência (' || to_char(p_seq_aprov) || ').';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM faixa_aprov_papel
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND papel_id = p_papel_id
     AND seq_aprov = v_seq_aprov_aux;
  --
  ------------------------------------------------------------
  -- renumeracao
  ------------------------------------------------------------
  v_seq_aprov_ant := 0;
  v_seq_aprov_ren := 0;
  --
  FOR r_fa IN c_fa
  LOOP
   IF r_fa.seq_aprov <> v_seq_aprov_ant THEN
    v_seq_aprov_ant := v_seq_aprov_ant + 1;
    --
    IF r_fa.seq_aprov <> v_seq_aprov_ant AND v_seq_aprov_ren = 0 THEN
     -- falha na sequencia. Salva a sequencia inicial
     -- para a renumeracao.
     v_seq_aprov_ren := r_fa.seq_aprov;
    END IF;
   END IF;
  END LOOP;
  --
  IF v_seq_aprov_ren > 0 THEN
   -- renumera dai pra frente
   FOR r_fa2 IN c_fa2
   LOOP
    UPDATE faixa_aprov_papel
       SET seq_aprov = seq_aprov - 1
     WHERE ROWID = r_fa2.rowid;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := 'Exclusão de papel';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   v_cod_objeto,
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 END papel_excluir;
 --
 --
 PROCEDURE papel_geral_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 26/09/2016
  -- DESCRICAO: Desassocia papel de todas as faixaa de aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_faixa        IN faixa_aprov.tipo_faixa%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_liga_os        NUMBER(5);
  v_liga_ao        NUMBER(5);
  v_liga_ec        NUMBER(5);
  --
  CURSOR c_fa IS
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov_os    fa,
          faixa_aprov_papel fp
    WHERE fa.faixa_aprov_id = fp.faixa_aprov_id
      AND fp.papel_id = p_papel_id
      AND v_liga_os = 1
   UNION
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov_ao    fa,
          faixa_aprov_papel fp
    WHERE fa.faixa_aprov_id = fp.faixa_aprov_id
      AND fp.papel_id = p_papel_id
      AND v_liga_ao = 1
   UNION
   SELECT fp.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov_papel fp
    WHERE fp.papel_id = p_papel_id
      AND v_liga_ec = 1
      AND NOT EXISTS (SELECT 1
             FROM faixa_aprov_ao fa
            WHERE fa.faixa_aprov_id = fp.faixa_aprov_id)
      AND NOT EXISTS (SELECT 1
             FROM faixa_aprov_os fo
            WHERE fo.faixa_aprov_id = fp.faixa_aprov_id)
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt      := 0;
  v_liga_os := 0;
  v_liga_ao := 0;
  v_liga_ec := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_faixa) IS NULL OR p_tipo_faixa NOT IN ('AO', 'OS', 'EC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faixa inválida (' || p_tipo_faixa || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_faixa = 'AO' THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_AO_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_liga_ao := 1;
  ELSIF p_tipo_faixa = 'OS' THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_OS_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_liga_os := 1;
  ELSIF p_tipo_faixa = 'EC' THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_EC_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_liga_ec := 1;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = nvl(p_papel_id, 0)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_fa IN c_fa
  LOOP
   faixa_aprov_pkg.papel_excluir(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 r_fa.faixa_aprov_id,
                                 r_fa.papel_id,
                                 r_fa.seq_aprov,
                                 p_erro_cod,
                                 p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END papel_geral_excluir;
 --
 --
 PROCEDURE seq_aprov_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 07/01/2015
  -- DESCRICAO: Atualiza sequencia de aprovacao dos papeis para uma determinada faixa de
  --   aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/03/2016  Subtipificacao da tabela faixa_aprov.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
  p_flag_sequencial   IN faixa_aprov.flag_sequencial%TYPE,
  p_vetor_papel_id    IN VARCHAR2,
  p_vetor_seq_aprov   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_delimitador     CHAR(1);
  v_papel_id        papel.papel_id%TYPE;
  v_seq_aprov_char  VARCHAR2(20);
  v_seq_aprov       faixa_aprov_papel.seq_aprov%TYPE;
  v_seq_aprov_ant   faixa_aprov_papel.seq_aprov%TYPE;
  v_vetor_papel_id  VARCHAR2(4000);
  v_vetor_seq_aprov VARCHAR2(4000);
  v_tipo_faixa      faixa_aprov.tipo_faixa%TYPE;
  v_cod_objeto      tipo_objeto.codigo%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
  CURSOR c_fa IS
   SELECT seq_aprov
     FROM faixa_aprov_papel
    WHERE faixa_aprov_id = p_faixa_aprov_id
    ORDER BY seq_aprov;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa faixa de aprovação não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_faixa
    INTO v_tipo_faixa
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  IF v_tipo_faixa = 'AO' THEN
   v_cod_objeto := 'FAIXA_APROV_AO';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_AO_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'OS' THEN
   v_cod_objeto := 'FAIXA_APROV_OS';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_OS_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSIF v_tipo_faixa = 'EC' THEN
   v_cod_objeto := 'FAIXA_APROV_EC';
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'FAIXA_APROV_EC_C',
                                 NULL,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_sequencial) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sequencial inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  DELETE FROM faixa_aprov_papel
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  v_vetor_papel_id  := p_vetor_papel_id;
  v_vetor_seq_aprov := p_vetor_seq_aprov;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0
  LOOP
   v_papel_id       := to_number(prox_valor_retornar(v_vetor_papel_id, v_delimitador));
   v_seq_aprov_char := prox_valor_retornar(v_vetor_seq_aprov, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel
    WHERE papel_id = nvl(v_papel_id, 0)
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(v_seq_aprov_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sequência inválida (' || v_seq_aprov_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_seq_aprov := nvl(to_number(v_seq_aprov_char), 0);
   --
   IF v_seq_aprov NOT BETWEEN 1 AND 19 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sequência inválida (' || v_seq_aprov_char || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM faixa_aprov_papel
    WHERE faixa_aprov_id = p_faixa_aprov_id
      AND papel_id = v_papel_id
      AND seq_aprov = v_seq_aprov;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existe papel repetido nessa sequência (' || v_seq_aprov_char || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO faixa_aprov_papel
    (faixa_aprov_id,
     papel_id,
     seq_aprov)
   VALUES
    (p_faixa_aprov_id,
     v_papel_id,
     v_seq_aprov);
  END LOOP;
  --
  UPDATE faixa_aprov
     SET flag_sequencial = p_flag_sequencial
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- verificacao da sequencia
  ------------------------------------------------------------
  v_seq_aprov_ant := 0;
  --
  FOR r_fa IN c_fa
  LOOP
   IF r_fa.seq_aprov <> v_seq_aprov_ant THEN
    v_seq_aprov_ant := v_seq_aprov_ant + 1;
    --
    IF r_fa.seq_aprov <> v_seq_aprov_ant THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A sequência deve começar de 1 e não pode pular números.';
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faixa_aprov_pkg.xml_gerar(p_faixa_aprov_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_faixa_aprov_id);
  v_compl_histor   := 'Alteração de sequência';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   v_cod_objeto,
                   'ALTERAR',
                   v_identif_objeto,
                   p_faixa_aprov_id,
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
 END seq_aprov_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/01/2017
  -- DESCRICAO: Subrotina que gera o xml da faixa de aprovacao para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/06/2018  Novo atributo fornec_interno
  ------------------------------------------------------------------------------------------
 (
  p_faixa_aprov_id IN faixa_aprov.faixa_aprov_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml        xmltype;
  v_xml_aux1   xmltype;
  v_xml_aux2   xmltype;
  v_xml_doc    VARCHAR2(100);
  v_tipo_faixa faixa_aprov.tipo_faixa%TYPE;
  --
  CURSOR c_pa IS
   SELECT pa.nome,
          fa.seq_aprov
     FROM faixa_aprov_papel fa,
          papel             pa
    WHERE fa.faixa_aprov_id = p_faixa_aprov_id
      AND fa.papel_id = pa.papel_id
    ORDER BY fa.seq_aprov;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT MAX(tipo_faixa)
    INTO v_tipo_faixa
    FROM faixa_aprov
   WHERE faixa_aprov_id = p_faixa_aprov_id;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  IF v_tipo_faixa = 'AO' THEN
   SELECT xmlconcat(xmlelement("faixa_aprov_id", fa.faixa_aprov_id),
                    xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                    xmlelement("tipo_faixa", fa.tipo_faixa),
                    xmlelement("sequencial", fa.flag_sequencial),
                    xmlelement("cliente", cl.apelido),
                    xmlelement("valor_de", numero_mostrar(f2.valor_de, 2, 'N')),
                    xmlelement("valor_ate", numero_mostrar(f2.valor_ate, 2, 'N')),
                    xmlelement("itens_a", f2.flag_itens_a),
                    xmlelement("itens_bc", f2.flag_itens_bc),
                    xmlelement("fornec_homolog", f2.fornec_homolog),
                    xmlelement("fornec_interno", f2.fornec_interno),
                    xmlelement("resultado_de", taxa_mostrar(f2.resultado_de)),
                    xmlelement("resultado_ate", taxa_mostrar(f2.resultado_ate)),
                    xmlelement("ativo", fa.flag_ativo),
                    xmlelement("comentario", fa.comentario))
     INTO v_xml
     FROM faixa_aprov    fa,
          faixa_aprov_ao f2,
          pessoa         cl
    WHERE fa.faixa_aprov_id = p_faixa_aprov_id
      AND fa.faixa_aprov_id = f2.faixa_aprov_id
      AND f2.cliente_id = cl.pessoa_id(+);
  ELSIF v_tipo_faixa = 'OS' THEN
   SELECT xmlconcat(xmlelement("faixa_aprov_id", fa.faixa_aprov_id),
                    xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                    xmlelement("tipo_faixa", fa.tipo_faixa),
                    xmlelement("sequencial", fa.flag_sequencial),
                    xmlelement("cliente", cl.apelido),
                    xmlelement("tipo_job", tj.nome),
                    xmlelement("complex_job", f2.complex_job),
                    xmlelement("iteracao_estim", f2.flag_aprov_est),
                    xmlelement("iteracao_exec", f2.flag_aprov_exe),
                    xmlelement("ativo", fa.flag_ativo),
                    xmlelement("comentario", fa.comentario))
     INTO v_xml
     FROM faixa_aprov    fa,
          faixa_aprov_os f2,
          pessoa         cl,
          tipo_job       tj
    WHERE fa.faixa_aprov_id = p_faixa_aprov_id
      AND fa.faixa_aprov_id = f2.faixa_aprov_id
      AND f2.cliente_id = cl.pessoa_id(+)
      AND f2.tipo_job_id = tj.tipo_job_id(+);
  ELSIF v_tipo_faixa = 'EC' THEN
   SELECT xmlconcat(xmlelement("faixa_aprov_id", fa.faixa_aprov_id),
                    xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                    xmlelement("tipo_faixa", fa.tipo_faixa),
                    xmlelement("sequencial", fa.flag_sequencial),
                    xmlelement("ativo", fa.flag_ativo),
                    xmlelement("comentario", fa.comentario))
     INTO v_xml
     FROM faixa_aprov fa
    WHERE fa.faixa_aprov_id = p_faixa_aprov_id;
  END IF;
  --
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlconcat(xmlelement("sequencia", r_pa.seq_aprov), xmlelement("papel", r_pa.nome))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux2)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("seq_aprovacao", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  -- junta tudo debaixo de "faixa_aprov"
  SELECT xmlagg(xmlelement("faixa_aprov", v_xml, v_xml_aux1))
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
END faixa_aprov_pkg;



/
