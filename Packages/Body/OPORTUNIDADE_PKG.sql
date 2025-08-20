--------------------------------------------------------
--  DDL for Package Body OPORTUNIDADE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "OPORTUNIDADE_PKG" IS
 --
 --
 PROCEDURE resp_int_tratar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/09/2020
  -- DESCRICAO: subrotina que verifica se o usuario pode ser responsavel
  --   interno e, caso a oportunidade nao tenha nenhum, marca como responsavel.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_opotunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id     IN usuario.usuario_id%TYPE,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_empresa_id oportunidade.empresa_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao
  ------------------------------------------------------------
  -- verifica se a oportunidade ja tem responsavel interno
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_opotunidade_id
     AND flag_responsavel = 'S';
  --
  IF v_qt = 0
  THEN
   -- oportunidade sem responsavel interno.
   -- verifica se esse usuario tem privilegio de responsavel interno
   SELECT empresa_id
     INTO v_empresa_id
     FROM oportunidade
    WHERE oportunidade_id = p_opotunidade_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'OPORTUN_RESP_INT_V', NULL, NULL, v_empresa_id) = 1
   THEN
    UPDATE oport_usuario
       SET flag_responsavel = 'S'
     WHERE oportunidade_id = p_opotunidade_id
       AND usuario_id = p_usuario_id;
   END IF;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END resp_int_tratar;
 --
 --
 PROCEDURE consistir_principal
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Consistencia de dados principais da OPORTUNIDADE.
  --   TIPO_CHAMADA: BD - usado como subrotina pelo banco
  --                 WEB - usado pelo wizard (pre-consistencia)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/03/2020  Novo parametro moeda
  -- Silvia            29/05/2020  Retirada do parametro moeda
  -- Silvia            15/09/2020  Novo parametro compl_origem
  -- Silvia            13/04/2022  Novos parametros de responsavel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_tipo_chamada         IN VARCHAR2,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_cliente_id           IN oportunidade.cliente_id%TYPE,
  p_flag_conflito        IN VARCHAR2,
  p_cliente_conflito_id  IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id           IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id   IN oportunidade.produto_cliente_id%TYPE,
  p_usuario_resp_id      IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN oportunidade.unid_negocio_resp_id%TYPE,
  p_origem               IN oportunidade.origem%TYPE,
  p_compl_origem         IN VARCHAR2,
  p_tipo_negocio         IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id     IN oportunidade.tipo_contrato_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt          INTEGER;
  v_exception   EXCEPTION;
  v_lbl_prodcli VARCHAR2(100);
  v_usa_resp_op VARCHAR2(100);
  v_lbl_un      VARCHAR2(100);
 BEGIN
  v_qt          := 0;
  v_lbl_prodcli := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_usa_resp_op := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_RESP_OPORT');
  v_lbl_un      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_chamada) IS NULL OR p_tipo_chamada NOT IN ('BD', 'WEB')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de chamada inválida (' || p_tipo_chamada || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_chamada = 'WEB' AND
     usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPORTUN_I', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 120
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Descrição não pode ter mais que 120 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_cliente_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_conflito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Conflito inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_conflito = 'S' AND nvl(p_cliente_conflito_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Cliente em Conflito é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_conflito = 'N' AND nvl(p_cliente_conflito_id, 0) <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Cliente em Conflito só deve ser preenchido quando indicado o conflito.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_conflito_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_cliente_conflito_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Cliente em Conflito não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_contato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Contato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_contato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Contato não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_lbl_prodcli || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE produto_cliente_id = p_produto_cliente_id
     AND pessoa_id = p_cliente_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_usa_resp_op = 'S' AND nvl(p_usuario_resp_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pela Oportunidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_unid_negocio_resp_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM unidade_negocio
    WHERE unidade_negocio_id = p_unid_negocio_resp_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_lbl_un || ' não existe ou não pertence a essa empresa (' ||
                  to_char(p_unid_negocio_resp_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_origem) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Origem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_origem', p_origem) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Origem inválida (' || p_origem || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_origem)) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento da origem não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_negocio) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo de Negócio é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_tipo_negocio', p_tipo_negocio) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Negócio inválido (' || p_tipo_negocio || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_contrato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo de Contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id
     AND empresa_id = p_empresa_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   ROLLBACK;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END consistir_principal;
 --
 --
 /*PROCEDURE            consistir_cenario
 ------------------------------------------------------------------------------------------
 -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/03/2019
 -- DESCRICAO: Consistencia de valores da OPORTUNIDADE.
 --   TIPO_CHAMADA: BD - usado como subrotina pelo banco
 --                 WEB - usado pelo wizard (pre-consistencia)
 --
 -- ALTERADO POR      DATA        MOTIVO ALTERACAO
 -- ----------------  ----------  ---------------------------------------------------------
 -- Silvia            29/05/2020  Novos parametros de cenario
 -- Silvia            13/04/2022  Novos parametros de responsavel
 -- Silvia            12/07/2022  Consistencia de responsavel obrigatorio
 -- Silvia            28/07/2022  Na chamada WEB, verifica cenario obrigatorio
 -- Ana Luiza         20/07/2023  Remoção da cenario/servico empresa, pois recebera valor
 --                               ja precificado da tab_preco
 -- Ana Luiza         17/08/2023  Adicao de consistencias para novas colunas da tab cenario
 ------------------------------------------------------------------------------------------
 (
   p_usuario_sessao_id              IN  NUMBER
 , p_empresa_id                     IN  oportunidade.empresa_id%TYPE
 , p_preco_id                       IN  tab_preco.preco_id%TYPE
 , p_tipo_chamada                   IN  VARCHAR2
 , p_cenario_id                     IN  cenario.cenario_id%TYPE
 , p_nome_cenario                   IN  VARCHAR2
 , p_num_parcelas                   IN  VARCHAR2
 , p_coment_parcelas                IN  VARCHAR2
 , p_flag_padrao                    IN  VARCHAR2
 , p_moeda                          IN  VARCHAR2
 , p_valor_cotacao                  IN  VARCHAR2
 , p_data_cotacao                   IN  VARCHAR2
 , p_flag_comissao                  IN  VARCHAR2
 , p_prazo_pagamento                IN  VARCHAR2
 , p_cond_pagamento                 IN  VARCHAR2
 , p_erro_cod                       OUT VARCHAR2
 , p_erro_msg                       OUT VARCHAR2
 )
 IS
   v_qt                             INTEGER;
   v_exception                      EXCEPTION;
   v_saida                          EXCEPTION;
   v_valor_cotacao                  cenario.valor_cotacao%TYPE;
   v_data_cotacao                   cenario.data_cotacao%TYPE;
   v_num_parcelas                   cenario.num_parcelas%TYPE;
   v_prazo_pagamento                cenario.prazo_pagamento%TYPE;
   v_valor_oportun                  oportunidade.valor_oportun%TYPE;
   v_valor_oportun_aux              oportunidade.valor_oportun%TYPE;
   v_flag_obriga_cenario            status_aux_oport.flag_obriga_cenario%TYPE;
   --ALCBO_270723
   v_preco_id                       tab_preco.preco_id%TYPE;
   v_cond_pagamento                 cenario.cond_pagamento%TYPE;
 --
 BEGIN
 --
 ------------------------------------------------------------
 -- verificacao de seguranca
 ------------------------------------------------------------
   IF TRIM(p_tipo_chamada) IS NULL OR p_tipo_chamada NOT IN ('BD','WEB') THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Tipo de chamada inválida (' || p_tipo_chamada || ').';
      RAISE v_exception;
   END IF;
 --
   IF NVL(p_empresa_id,0) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A especificação da empresa é obrigatória.';
      RAISE v_exception;
   END IF;
 --
   SELECT MAX(flag_obriga_cenario)
     INTO v_flag_obriga_cenario
     FROM status_aux_oport
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = 'ANDA'
      AND flag_padrao = 'S';
 --
   IF p_tipo_chamada = 'WEB' AND
      v_flag_obriga_cenario = 'N' AND TRIM(p_nome_cenario) IS NULL THEN
      -- chamada via Wizard. Qdo o cenario nao eh obrigatorio e o nome
      -- do cenario nao eh informado, sai sem consistir.
      RAISE v_saida;
   END IF;
 --
   IF TRIM(p_nome_cenario) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento do Nome do Cenário é obrigatório.';
      RAISE v_exception;
   END IF;
 --
   IF LENGTH(TRIM(p_nome_cenario)) > 100 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O Nome do Cenário não pode ter mais que 100 caracteres.';
      RAISE v_exception;
   END IF;
 --
   IF flag_validar(p_flag_padrao) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Flag padrão inválido (' || p_flag_padrao ||  ').';
      RAISE v_exception;
   END IF;
 --
   IF TRIM(p_moeda) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento da Moeda é obrigatório.';
      RAISE v_exception;
   END IF;
 --
   IF util_pkg.desc_retornar('moeda',p_moeda) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Moeda inválida (' || p_moeda || ').';
      RAISE v_exception;
   END IF;
 --
   IF numero_validar(p_valor_cotacao) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da cotação da moeda inválido (' || p_valor_cotacao || ').';
      RAISE v_exception;
   END IF;
 --
   v_valor_cotacao := NVL(numero_converter(p_valor_cotacao),0);
 --
   IF data_validar(p_data_cotacao) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Data da cotação inválido (' || p_data_cotacao || ').';
      RAISE v_exception;
   END IF;
 --
   v_data_cotacao := data_converter(p_data_cotacao);
 --
   IF p_moeda = 'REAL' AND (v_data_cotacao IS NOT NULL OR v_valor_cotacao > 0) THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Para essa moeda, a cotação não deve ser informada.';
      RAISE v_exception;
   END IF;
 --
   IF p_moeda <> 'REAL' AND (v_data_cotacao IS NULL OR v_valor_cotacao = 0) THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Para essa moeda, a cotação deve ser informada.';
      RAISE v_exception;
   END IF;
 --ALCBO_170823
   IF NVL(p_preco_id,0) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento do Rate Card é obrigatório.';
      RAISE v_exception;
   END IF;
 --
   SELECT MAX(PRECO_ID)
   INTO v_preco_id
   FROM tab_preco
   WHERE preco_id = p_preco_id
   AND empresa_id = p_empresa_id;
 --
   IF v_preco_id IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Rate Card não existe ou não pertence à empresa.';
      RAISE v_exception;
   END IF;
 --
   IF flag_validar(p_flag_comissao) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Flag padrão inválido (' || p_flag_comissao ||  ').';
      RAISE v_exception;
   END IF;
 --
   IF TRIM(p_prazo_pagamento) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Prazo de Pagamento é obrigatório';
      RAISE v_exception;
   END IF;
 --
   IF inteiro_validar(p_prazo_pagamento) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Prazo de Pagamento inválido (' || p_prazo_pagamento || ').';
      RAISE v_exception;
   END IF;
 --
   v_prazo_pagamento := NVL(TO_NUMBER(p_prazo_pagamento),0);
 --
   IF v_prazo_pagamento < 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Prazo de Pagamento inválido (' || v_prazo_pagamento || ').';
      RAISE v_exception;
   END IF;
 --
   IF v_valor_oportun <> v_valor_oportun_aux THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O Total de produtos deve bater com o Budget Total.';
      RAISE v_exception;
   END IF;
 --
   IF inteiro_validar(p_num_parcelas) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de Parcelas inválido (' || p_num_parcelas || ').';
      RAISE v_exception;
   END IF;
 --
   v_num_parcelas := NVL(TO_NUMBER(p_num_parcelas),0);
 --
   IF v_num_parcelas <=0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de Parcelas inválido (' || p_num_parcelas || ').';
      RAISE v_exception;
   END IF;
 --ALCBO_250823
   IF TRIM(p_coment_parcelas) IS NULL THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Comentário de Condição de Pagamento é obrigatório';
        RAISE v_exception;
   END IF;
   --
   IF LENGTH(TRIM(p_coment_parcelas)) > 2000 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Os Comentários da condição de pagamento não podem ' ||
                    'ter mais que 2000 caracteres.';
      RAISE v_exception;
   END IF;
 --
  IF TRIM(p_cond_pagamento) IS NULL THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Condição de Pagamento é obrigatório';
        RAISE v_exception;
   END IF;
 --
   IF TRIM(p_cond_pagamento) IS NULL THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Condição de Pagamento é obrigatório';
        RAISE v_exception;
   END IF;
 --
   IF inteiro_validar(p_cond_pagamento) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Condição de Pagamento inválido (' || p_cond_pagamento || ').';
      RAISE v_exception;
   END IF;
 --
   v_cond_pagamento := NVL(TO_NUMBER(p_cond_pagamento),0);
 --
   IF v_cond_pagamento < 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Condição de Pagamento inválido (' || v_cond_pagamento || ').';
      RAISE v_exception;
   END IF;
 --ALCBO_250823F
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
 --
 EXCEPTION
   WHEN v_saida THEN
        p_erro_cod := '00000';
        p_erro_msg := 'Operação realizada com sucesso.';
   WHEN v_exception THEN
        ROLLBACK;
   WHEN OTHERS THEN
        ROLLBACK;
        p_erro_cod := SQLCODE;
        p_erro_msg := SUBSTR(SQLERRM||' Linha Erro: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 200);
 END consistir_cenario;*/
 --
 --
 PROCEDURE adicionar_wizard
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Inclusão de OPORTUNIDADE via wizard.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/12/2019  Indicacao de usuario comissionado
  -- Silvia            02/03/2020  Inclusao de moeda
  -- Silvia            29/05/2020  Novos parametros de moeda 
  -- Silvia            15/09/2020  Novo parametro compl_origem
  -- Silvia            12/04/2022  Novos parametros para responsavel
  -- Silvia            28/07/2022  Teste de cenario obrigatorio
  -- Silvia            01/08/2022  Enderecamento automatico de responsavel
  -- Joel Dias         21/07/2022  Inclusão do ponto de integração OPORTUNIDADE_JOB_ADICIONAR
  -- Ana Luiza         31/07/2023  Inclusao atributos novos tabela de cenario
  -- Ana Luiza         16/08/2023  Inclusao atributos novos tabela de cenario
  -- Ana Luiza         20/10/2023  Remocao do passo 2, adicionar cenario
  -- Ana Luiza         07/12/2023  Inclusao novos parametros para chamada geracao negocio
  -- Ana Luiza         22/07/2024  Consistencia passo 3 alterado de lugar
  -- Ana Luiza         10/01/2025  Criado condicao para chamar jobone_self se parametro ligado
  -- Ana Luiza         27/02/2025  Removido condicao implementada no dia 10/01/2025 apos ajustar
  --                               commit em jobone_self
  -- Ana Luiza         11/03/2025  Adicao de p_flag_commit em chamada de geracao negocio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_preco_id                IN tab_preco.preco_id%TYPE,
  p_nome                    IN oportunidade.nome%TYPE,
  p_cliente_id              IN oportunidade.cliente_id%TYPE,
  p_flag_conflito           IN VARCHAR2,
  p_cliente_conflito_id     IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id              IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id      IN oportunidade.produto_cliente_id%TYPE,
  p_usuario_resp_id         IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id    IN oportunidade.unid_negocio_resp_id%TYPE,
  p_origem                  IN oportunidade.origem%TYPE,
  p_compl_origem            IN VARCHAR2,
  p_tipo_negocio            IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id        IN oportunidade.tipo_contrato_id%TYPE,
  p_usuario_comissionado_id IN oport_usuario.usuario_id%TYPE,
  p_nome_cenario            IN VARCHAR2,
  p_moeda                   IN VARCHAR2,
  p_valor_cotacao           IN VARCHAR2,
  p_data_cotacao            IN VARCHAR2,
  p_num_parcelas            IN VARCHAR2,
  p_coment_parcelas         IN VARCHAR2,
  p_flag_comissao           IN VARCHAR2,
  p_prazo_pagamento         IN VARCHAR2,
  p_cond_pagamento          IN VARCHAR2,
  p_int1_data               IN VARCHAR2,
  p_int1_usuario_id         IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato       IN VARCHAR2,
  p_int1_descricao          IN interacao.descricao%TYPE,
  p_perc_prob_fech          IN VARCHAR2,
  p_data_prov_fech          IN VARCHAR2,
  p_int2_data               IN VARCHAR2,
  p_int2_usuario_id         IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao          IN interacao.descricao%TYPE,
  p_flag_sem_def_valores    IN VARCHAR2,
  p_vetor_servico           IN VARCHAR2,
  p_vetor_valor             IN VARCHAR2,
  p_flag_sem_valor          IN VARCHAR2,
  p_oportunidade_id         OUT oportunidade.oportunidade_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_oportunidade_id     oportunidade.oportunidade_id%TYPE;
  v_numero_oport        oportunidade.numero%TYPE;
  v_status_aux_oport_id oportunidade.status_aux_oport_id%TYPE;
  v_status_oport        oportunidade.status%TYPE;
  v_perc_prob_fech      interacao.perc_prob_fech%TYPE;
  v_data_prov_fech      interacao.data_prov_fech%TYPE;
  v_data_interacao1     interacao.data_interacao%TYPE;
  v_data_interacao2     interacao.data_interacao%TYPE;
  v_cenario_id          cenario.cenario_id%TYPE;
  v_numero              NUMBER(20);
  v_data_atual          DATE;
  v_xml_atual           CLOB;
  v_apelido             pessoa.apelido%TYPE;
  v_flag_obriga_cenario status_aux_oport.flag_obriga_cenario%TYPE;
  --
  v_perc_imposto_precif  cenario.perc_imposto_precif%TYPE;
  v_num_dias_elab_precif VARCHAR2(100);
  --
  v_data_prazo cenario.data_prazo%TYPE;
  --  
  v_num_parcelas    cenario.num_parcelas%TYPE;
  v_valor_cotacao   cenario.valor_cotacao%TYPE;
  v_data_cotacao    cenario.data_cotacao%TYPE;
  v_prazo_pagamento cenario.prazo_pagamento%TYPE;
  v_cond_pagamento  cenario.cond_pagamento%TYPE;
  --v_restringir_periodo_job_ctr VARCHAR2(20);--ALCBO_270225
  --
 BEGIN
  v_qt              := 0;
  p_oportunidade_id := 0;
  v_data_atual      := SYSDATE;
  --ALCBO_270225
  /*v_restringir_periodo_job_ctr := empresa_pkg.parametro_retornar(p_empresa_id,
  'RESTRINGIR_PERIODO_JOB_CTR');*/
  --
  -- status em que a oportunidade eh criada
  v_status_oport := 'ANDA';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPORTUN_I', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(status_aux_oport_id),
         MAX(flag_obriga_cenario)
    INTO v_status_aux_oport_id,
         v_flag_obriga_cenario
    FROM status_aux_oport
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = v_status_oport
     AND flag_padrao = 'S';
  --
  IF v_status_aux_oport_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão para o status ' || v_status_oport ||
                 ' não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  oportunidade_pkg.consistir_principal(p_usuario_sessao_id,
                                       p_empresa_id,
                                       'BD',
                                       0,
                                       p_nome,
                                       p_cliente_id,
                                       p_flag_conflito,
                                       p_cliente_conflito_id,
                                       p_contato_id,
                                       p_produto_cliente_id,
                                       p_usuario_resp_id,
                                       p_unid_negocio_resp_id,
                                       p_origem,
                                       p_compl_origem,
                                       p_tipo_negocio,
                                       p_tipo_contrato_id,
                                       p_erro_cod,
                                       p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera o numero da oportunidade (geral p/ todas as empresas)
  ------------------------------------------------------------
  SELECT nvl(MAX(to_number(substr(numero, 3))), 0) + 1
    INTO v_numero
    FROM oportunidade;
  --
  IF length(v_numero) <= 4
  THEN
   v_numero_oport := 'OP' || TRIM(to_char(v_numero, '0000'));
  ELSE
   v_numero_oport := 'OP' || TRIM(to_char(v_numero));
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE numero = v_numero_oport;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de Oportunidade já existe (' || v_numero_oport || ').';
   RAISE v_exception;
  END IF;
  --
  --                     
  SELECT seq_oportunidade.nextval
    INTO v_oportunidade_id
    FROM dual;
  --ALCBO_220724
  --MOVIDO CONSISTENCIA PASSO 3 AQUI
  ------------------------------------------------------------
  -- atualizacao dos interacoes (passo 3)
  ------------------------------------------------------------
  IF TRIM(p_int1_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da Interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int1_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da Interação inválida (' || p_int1_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao1 := data_converter(p_int1_data);
  --
  IF nvl(p_int1_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Autor/Responsável pela interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Meio de Contato da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_meio_contato', p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Meio de Contato inválido (' || p_int1_meio_contato || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_int1_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição/Resumo da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_perc_prob_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Probabilidade de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_prob_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual da Probabilidade de Fechamento inválido (' || p_perc_prob_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_prob_fech := nvl(taxa_converter(p_perc_prob_fech), 0);
  --
  IF TRIM(p_data_prov_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data Provável de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prov_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data Provável de Fechamento inválida (' || p_data_prov_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prov_fech := data_converter(p_data_prov_fech);
  --
  IF TRIM(p_int2_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int2_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da próxima interação inválida (' || p_int2_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao2 := data_converter(p_int2_data);
  --
  IF nvl(p_int2_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pela próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_int2_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  INSERT INTO oportunidade
   (oportunidade_id,
    empresa_id,
    cliente_id,
    usuario_solic_id,
    contato_id,
    produto_cliente_id,
    usuario_resp_id,
    unid_negocio_resp_id,
    flag_conflito,
    cliente_conflito_id,
    numero,
    nome,
    data_entrada,
    status,
    data_status,
    status_aux_oport_id,
    origem,
    compl_origem,
    tipo_negocio,
    tipo_contrato_id,
    valor_oportun)
  VALUES
   (v_oportunidade_id,
    p_empresa_id,
    p_cliente_id,
    p_usuario_sessao_id,
    p_contato_id,
    p_produto_cliente_id,
    zvl(p_usuario_resp_id, NULL),
    zvl(p_unid_negocio_resp_id, NULL),
    p_flag_conflito,
    zvl(p_cliente_conflito_id, NULL),
    v_numero_oport,
    TRIM(p_nome),
    v_data_atual,
    'ANDA',
    v_data_atual,
    zvl(v_status_aux_oport_id, NULL),
    TRIM(p_origem),
    TRIM(p_compl_origem),
    TRIM(p_tipo_negocio),
    p_tipo_contrato_id,
    0);
  --ALCBO_071223
  ------------------------------------------------------------
  --Potencial de geracao de negocio
  ------------------------------------------------------------
  oportunidade_pkg.pontencial_geracao_negocio_gerar(p_usuario_sessao_id,
                                                    p_empresa_id,
                                                    v_oportunidade_id,
                                                    p_flag_sem_def_valores,
                                                    p_vetor_servico,
                                                    p_vetor_valor,
                                                    p_flag_sem_valor,
                                                    'N', --p_flag_commit ALCBO_110325
                                                    p_erro_cod,
                                                    p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento automatico do usuario responsavel
  ------------------------------------------------------------
  IF nvl(p_usuario_resp_id, 0) > 0
  THEN
   -- endereca o usuario responsavel.
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_usuario_resp_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      v_oportunidade_id,
                                      p_usuario_resp_id,
                                      v_apelido || ' endereçado automaticamente (responsável)',
                                      'Criação da Oportunidade',
                                      p_erro_cod,
                                      p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao dos valores (passo 2)
  ------------------------------------------------------------
  /*
  --ALCBO_200723
  IF v_flag_obriga_cenario = 'S' OR TRIM(p_nome_cenario) IS NOT NULL THEN
     cenario_pkg.consistir_cenario(
                             p_usuario_sessao_id
                            ,p_empresa_id   
                            ,p_preco_id
                            ,'BD'
                            ,0
                            ,p_nome_cenario
                            ,p_num_parcelas
                            ,p_coment_parcelas
                            ,'S'
                            ,p_moeda
                            ,p_valor_cotacao
                            ,p_data_cotacao
                            ,p_flag_comissao
                            ,p_prazo_pagamento
                            ,p_cond_pagamento
                            ,p_erro_cod
                            ,p_erro_msg
                            );
     -- 
     IF p_erro_cod <> '00000' THEN
        RAISE v_exception;
     END IF;
     --
     SELECT seq_cenario.NEXTVAL
     INTO v_cenario_id
     FROM dual;
     --
     v_num_parcelas    := numero_converter(p_num_parcelas);
     v_valor_cotacao   := numero_converter(p_valor_cotacao);
     v_data_cotacao    := data_converter(p_data_cotacao);
     v_prazo_pagamento := numero_converter(p_prazo_pagamento);
     --
     v_num_dias_elab_precif := empresa_pkg.parametro_retornar(p_empresa_id, 
                                                           'NUM_DIAS_ELAB_PRECIF');
     v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                        sysdate,
                                                        v_num_dias_elab_precif,'S'); 
     v_cond_pagamento := numero_converter(p_cond_pagamento);     
     --
     v_perc_imposto_precif := empresa_pkg.parametro_retornar
                           (p_empresa_id, 'PERC_IMPOSTO_PRECIF');    
  
   INSERT INTO cenario
     (cenario_id,
      oportunidade_id,
      num_cenario,
      nome,
      data_entrada,
      num_parcelas,
      prazo_pagamento,
      coment_parcelas,
      flag_padrao,
      flag_comissao_venda,
      moeda,
      valor_cotacao,
      data_cotacao,
      preco_id,
      briefing,
      data_prazo,
      status,
      valor,
      status_margem,
      perc_imposto_precif,
      cond_pagamento,
      status_aprov_rc)
   VALUES
     (v_cenario_id,
      v_oportunidade_id,
      1,
      TRIM(p_nome_cenario),
      v_data_atual,
      v_num_parcelas,
      v_prazo_pagamento,
      TRIM(p_coment_parcelas),
      'S',
      p_flag_comissao,
      p_moeda,
      v_valor_cotacao,
      v_data_cotacao,
      p_preco_id,
      '',
      v_data_prazo,
      'PREP',
      0,
      'PEND',
      v_perc_imposto_precif,
      v_cond_pagamento,
      'NA');
  
       INSERT INTO cenario_mod_contr (cenario_mod_contr_id, cenario_id,
            ordem, codigo, descricao, flag_margem, flag_honor,
            flag_encargo, flag_imposto, tipo_item_codigo)
     SELECT SEQ_cenario_mod_contr.NEXTVAL, v_cenario_id,
            ordem, codigo, descricao, flag_margem, flag_honor,
            flag_encargo, flag_imposto, tipo_item_codigo
       FROM modal_contratacao
      WHERE empresa_id = p_empresa_id;
  END IF;
  */
  --ALCBO_220723 - REMOVIDO CONSISTENCIA PASSO 3 DAQUI
  --
  INSERT INTO interacao
   (interacao_id,
    oportunidade_id,
    usuario_resp_id,
    data_entrada,
    data_interacao,
    descricao,
    meio_contato,
    perc_prob_fech,
    data_prov_fech,
    usuario_prox_int_id,
    data_prox_int,
    desc_prox_int,
    status_aux_oport_id)
  VALUES
   (seq_interacao.nextval,
    v_oportunidade_id,
    p_int1_usuario_id,
    SYSDATE,
    v_data_interacao1,
    TRIM(p_int1_descricao),
    p_int1_meio_contato,
    v_perc_prob_fech,
    v_data_prov_fech,
    p_int2_usuario_id,
    v_data_interacao2,
    TRIM(p_int2_descricao),
    zvl(v_status_aux_oport_id, NULL));
  --
  UPDATE oportunidade
     SET perc_prob_fech = v_perc_prob_fech,
         data_prov_fech = v_data_prov_fech,
         data_prox_int  = v_data_interacao2
   WHERE oportunidade_id = v_oportunidade_id;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  oportunidade_pkg.enderecar_automatico(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_oportunidade_id,
                                        p_erro_cod,
                                        p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do autor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = v_oportunidade_id
     AND usuario_id = p_int1_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int1_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      v_oportunidade_id,
                                      p_int1_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Criação da Oportunidade',
                                      p_erro_cod,
                                      p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do responsavel pela proxima
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = v_oportunidade_id
     AND usuario_id = p_int2_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int2_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      v_oportunidade_id,
                                      p_int2_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Criação da Oportunidade',
                                      p_erro_cod,
                                      p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario comissionado
  ------------------------------------------------------------
  IF nvl(p_usuario_comissionado_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_usuario
    WHERE oportunidade_id = v_oportunidade_id
      AND usuario_id = p_usuario_comissionado_id;
   --
   IF v_qt = 0
   THEN
    SELECT apelido
      INTO v_apelido
      FROM pessoa
     WHERE usuario_id = p_usuario_comissionado_id;
    --
    -- a subrotina marca como: com co-ender, sem pula notif
    oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                       'N',
                                       'S',
                                       'N',
                                       p_empresa_id,
                                       v_oportunidade_id,
                                       p_usuario_comissionado_id,
                                       v_apelido || ' indicado como comissionado',
                                       'Criação da Oportunidade',
                                       p_erro_cod,
                                       p_erro_msg);
    -- 
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   UPDATE oport_usuario
      SET flag_comissionado = 'S'
    WHERE oportunidade_id = v_oportunidade_id
      AND usuario_id = p_usuario_comissionado_id;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'INCLUIR',
                   v_identif_objeto,
                   v_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --ALCBO_270225
  p_oportunidade_id := v_oportunidade_id;
  p_erro_cod        := '00000';
  p_erro_msg        := 'Operação realizada com sucesso.';
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------                        
  it_controle_pkg.integrar('OPORTUNIDADE_JOB_ADICIONAR',
                           p_empresa_id,
                           p_oportunidade_id,
                           'N',
                           p_erro_cod,
                           p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de Oportunidade já existe (' || v_numero_oport ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar_wizard;
 --
 --
 PROCEDURE atualizar_principal
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Atualização de OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/03/2020  Inclusao de moeda
  -- Silvia            29/05/2020  Retirada de moeda
  -- Silvia            15/09/2020  Novo parametro compl_origem
  -- Silvia            12/04/2022  Novos parametros para responsavel
  -- Silvia            01/08/2022  Enderecamento automatico de responsavel
  -- Ana Luiza         07/12/2023  Inclusao novos parametros para chamada geracao negocio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_nome                 IN oportunidade.nome%TYPE,
  p_cliente_id           IN oportunidade.cliente_id%TYPE,
  p_flag_conflito        IN VARCHAR2,
  p_cliente_conflito_id  IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id           IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id   IN oportunidade.produto_cliente_id%TYPE,
  p_origem               IN oportunidade.origem%TYPE,
  p_compl_origem         IN VARCHAR2,
  p_tipo_negocio         IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id     IN oportunidade.tipo_contrato_id%TYPE,
  p_usuario_resp_id      IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN oportunidade.unid_negocio_resp_id%TYPE,
  p_flag_sem_def_valores IN VARCHAR2,
  p_vetor_servico        IN VARCHAR2,
  p_vetor_valor          IN VARCHAR2,
  p_flag_sem_valor       IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_apelido        pessoa.apelido%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  oportunidade_pkg.consistir_principal(p_usuario_sessao_id,
                                       p_empresa_id,
                                       'BD',
                                       p_oportunidade_id,
                                       p_nome,
                                       p_cliente_id,
                                       p_flag_conflito,
                                       p_cliente_conflito_id,
                                       p_contato_id,
                                       p_produto_cliente_id,
                                       p_usuario_resp_id,
                                       p_unid_negocio_resp_id,
                                       p_origem,
                                       p_compl_origem,
                                       p_tipo_negocio,
                                       p_tipo_contrato_id,
                                       p_erro_cod,
                                       p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oportunidade
     SET nome                 = TRIM(p_nome),
         contato_id           = p_contato_id,
         cliente_id           = p_cliente_id,
         produto_cliente_id   = p_produto_cliente_id,
         flag_conflito        = p_flag_conflito,
         cliente_conflito_id  = zvl(p_cliente_conflito_id, NULL),
         origem               = TRIM(p_origem),
         compl_origem         = TRIM(p_compl_origem),
         tipo_negocio         = TRIM(p_tipo_negocio),
         tipo_contrato_id     = p_tipo_contrato_id,
         usuario_resp_id      = zvl(p_usuario_resp_id, NULL),
         unid_negocio_resp_id = zvl(p_unid_negocio_resp_id, NULL)
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- enderecamento automatico do usuario responsavel
  ------------------------------------------------------------
  IF nvl(p_usuario_resp_id, 0) > 0
  THEN
   -- endereca o usuario responsavel.
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_usuario_resp_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      p_oportunidade_id,
                                      p_usuario_resp_id,
                                      v_apelido || ' endereçado automaticamente (responsável)',
                                      'Alteração da Oportunidade',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  --ALCBO_071223
  ------------------------------------------------------------
  --Potencial de geracao de negocio
  ------------------------------------------------------------
  oportunidade_pkg.pontencial_geracao_negocio_gerar(p_usuario_sessao_id,
                                                    p_empresa_id,
                                                    p_oportunidade_id,
                                                    p_flag_sem_def_valores,
                                                    p_vetor_servico,
                                                    p_vetor_valor,
                                                    p_flag_sem_valor,
                                                    'N', --p_flag_commit ALCBO_110325
                                                    p_erro_cod,
                                                    p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport;
  v_compl_histor   := 'Alteração principal';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar_principal;
 --
 --
 PROCEDURE atualizar_comissionados
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/12/2019
  -- DESCRICAO: Alteracao em lista de indicacao de comissionamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id    IN oportunidade.oportunidade_id%TYPE,
  p_vetor_usuarios     IN VARCHAR2,
  p_vetor_comissionado IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_oport       oportunidade.numero%TYPE;
  v_status_oport       oportunidade.status%TYPE;
  v_vetor_usuarios     VARCHAR2(2000);
  v_vetor_comissionado VARCHAR2(2000);
  v_delimitador        CHAR(1);
  v_usuario_id         usuario.usuario_id%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_flag_comissionado  VARCHAR2(10);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  v_delimitador        := '|';
  v_vetor_usuarios     := rtrim(p_vetor_usuarios);
  v_vetor_comissionado := rtrim(p_vetor_comissionado);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id        := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   v_flag_comissionado := nvl(prox_valor_retornar(v_vetor_comissionado, v_delimitador), 'N');
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_comissionado NOT IN ('S', 'N')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag comissionado inválido (' || v_flag_comissionado || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE oport_usuario
      SET flag_comissionado = v_flag_comissionado
    WHERE oportunidade_id = p_oportunidade_id
      AND usuario_id = v_usuario_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport;
  v_compl_histor   := 'Alteração de comissionados';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar_comissionados;
 --
 --
 PROCEDURE atualizar_responsavel
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/09/2020
  -- DESCRICAO: define o responsavel interno pela oportunidade (apenas 1). Quando
  --  usuario_id = 0, desmarca todos os responsaveis internos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_apelido        pessoa.apelido%TYPE;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oport_usuario
     SET flag_responsavel = 'N'
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF nvl(p_usuario_id, 0) > 0
  THEN
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'OPORTUN_RESP_INT_V', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário ' || v_apelido || ' não tem privilégio para ' ||
                  'ser o responsável pela condução da oportunidade.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_usuario
    WHERE oportunidade_id = p_oportunidade_id
      AND usuario_id = p_usuario_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO oport_usuario
     (oportunidade_id,
      usuario_id,
      flag_comissionado,
      flag_responsavel)
    VALUES
     (p_oportunidade_id,
      p_usuario_id,
      'N',
      'S');
   ELSE
    UPDATE oport_usuario
       SET flag_responsavel = 'S'
     WHERE oportunidade_id = p_oportunidade_id
       AND usuario_id = p_usuario_id;
   END IF;
  END IF; -- fim do IF NVL(p_usuario_id,0) > 0
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport;
  v_compl_histor   := 'Alteração de resp pela condução: ' || nvl(v_apelido, 'ND');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar_responsavel;
 --
 --
 PROCEDURE interacao_andam_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/07/2019
  -- DESCRICAO: Inclusão de INTERACAO DE OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/06/2021  Deixa repetir data da interacao.
  -- Silvia            27/07/2022  Consistencia de cenario de acordo c/ status/etapa
  -- Ana Luiza         16/12/2024  Adicionado novo parametro de empresa que avanca etapa da op
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id     IN oportunidade.oportunidade_id%TYPE,
  p_int1_data           IN VARCHAR2,
  p_int1_usuario_id     IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato   IN VARCHAR2,
  p_int1_descricao      IN interacao.descricao%TYPE,
  p_perc_prob_fech      IN VARCHAR2,
  p_data_prov_fech      IN VARCHAR2,
  p_status_aux_oport_id IN oportunidade.status_aux_oport_id%TYPE,
  p_int2_data           IN VARCHAR2,
  p_int2_usuario_id     IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao      IN interacao.descricao%TYPE,
  p_interacao_id        OUT interacao.interacao_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_numero_oport            oportunidade.numero%TYPE;
  v_status_aux_oport_id_old status_aux_oport.status_aux_oport_id%TYPE;
  v_status_oport            oportunidade.status%TYPE;
  v_interacao_id            interacao.interacao_id%TYPE;
  v_perc_prob_fech          interacao.perc_prob_fech%TYPE;
  v_data_prov_fech          interacao.data_prov_fech%TYPE;
  v_data_interacao1         interacao.data_interacao%TYPE;
  v_data_interacao2         interacao.data_interacao%TYPE;
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  v_apelido                 pessoa.apelido%TYPE;
  v_flag_obriga_cenario     status_aux_oport.flag_obriga_cenario%TYPE;
  v_nome_etapa              status_aux_oport.nome%TYPE;
  v_avancar_etapa_oport     VARCHAR2(100);
  v_meio_contato            VARCHAR2(100);
  v_descricao               VARCHAR2(100);
  v_status_atual            VARCHAR2(100);
  --
 BEGIN
  v_qt           := 0;
  p_interacao_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_aux_oport_id
    INTO v_numero_oport,
         v_status_oport,
         v_status_aux_oport_id_old
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPORTUN_A', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_int1_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da Interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int1_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da Interação inválida (' || p_int1_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao1 := data_converter(p_int1_data);
  --
  IF nvl(p_int1_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Autor/Responsável pela interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Meio de Contato da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_meio_contato', p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Meio de Contato inválido (' || p_int1_meio_contato || ').';
   RAISE v_exception;
  END IF;
  --
  /*
  IF p_int1_descricao IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da Descrição/Resumo da interação é obrigatório.';
     RAISE v_exception;
  END IF;
  */
  --
  IF TRIM(p_perc_prob_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Probabilidade de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_prob_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual da Probabilidade de Fechamento inválido (' || p_perc_prob_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_prob_fech := nvl(taxa_converter(p_perc_prob_fech), 0);
  --
  IF TRIM(p_data_prov_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data Provável de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prov_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data Provável de Fechamento inválida (' || p_data_prov_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prov_fech := data_converter(p_data_prov_fech);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM status_aux_oport
   WHERE empresa_id = p_empresa_id
     AND status_aux_oport_id = nvl(p_status_aux_oport_id, 0)
     AND cod_status_pai = v_status_oport;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Etapa da Oportunidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(MAX(flag_obriga_cenario), 'N'),
         nvl(MAX(nome), 'ND')
    INTO v_flag_obriga_cenario,
         v_nome_etapa
    FROM status_aux_oport
   WHERE status_aux_oport_id = p_status_aux_oport_id;
  --
  IF v_flag_obriga_cenario = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM cenario
    WHERE oportunidade_id = p_oportunidade_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Etapa ' || v_nome_etapa ||
                  ' exige que a Oportunidade tenha ao menos um Cenário.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_int2_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int2_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da próxima interação inválida (' || p_int2_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao2 := data_converter(p_int2_data);
  --
  IF nvl(p_int2_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pela próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_int2_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM interacao
     WHERE oportunidade_id = p_oportunidade_id
       AND data_interacao = v_data_interacao1;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Já existe uma interação registrada nessa data ('||
                     data_mostrar(v_data_interacao1) || ').';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_interacao.nextval
    INTO v_interacao_id
    FROM dual;
  --
  INSERT INTO interacao
   (interacao_id,
    oportunidade_id,
    usuario_resp_id,
    data_entrada,
    data_interacao,
    descricao,
    meio_contato,
    perc_prob_fech,
    data_prov_fech,
    usuario_prox_int_id,
    data_prox_int,
    desc_prox_int,
    status_aux_oport_id)
  VALUES
   (v_interacao_id,
    p_oportunidade_id,
    p_int1_usuario_id,
    SYSDATE,
    v_data_interacao1,
    TRIM(p_int1_descricao),
    p_int1_meio_contato,
    v_perc_prob_fech,
    v_data_prov_fech,
    p_int2_usuario_id,
    v_data_interacao2,
    TRIM(p_int2_descricao),
    p_status_aux_oport_id);
  --
  IF v_status_aux_oport_id_old <> p_status_aux_oport_id
  THEN
   UPDATE oportunidade
      SET status_aux_oport_id = p_status_aux_oport_id
    WHERE oportunidade_id = p_oportunidade_id;
  END IF;
  --
  UPDATE oportunidade
     SET perc_prob_fech = v_perc_prob_fech,
         data_prov_fech = v_data_prov_fech,
         data_prox_int  = v_data_interacao2
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- enderecamento do autor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_int1_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int1_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      p_oportunidade_id,
                                      p_int1_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Novo Follow-up',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do responsavel pela proxima
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_int2_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int2_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      p_oportunidade_id,
                                      p_int2_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Novo Follow-up',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'INTERAGIR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_status_aux_oport_id_old <> p_status_aux_oport_id
  THEN
   v_identif_objeto := to_char(v_numero_oport);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'OPORTUNIDADE',
                    'ALTERAR_STATUS',
                    v_identif_objeto,
                    p_oportunidade_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    v_xml_antes,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  p_interacao_id := v_interacao_id;
  p_erro_cod     := '00000';
  p_erro_msg     := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END interacao_andam_adicionar;
 --
 --
 PROCEDURE interacao_ganha_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/07/2019
  -- DESCRICAO: Nova interacao com mudanca de status para conclusão com ganho
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/03/2020  Inclusao de pais
  -- Silvia            15/05/2020  Retirada do vetor de papel
  -- Silvia            28/05/2020  Novo parametro usuario resp contrato
  -- Silvia            14/08/2020  Nao gera contratos na empresa caso a oport ja tenha
  -- Silvia            04/10/2020  Grava data atual como data_entrada do contrato
  -- Silvia            15/01/2021  Novos parametros p/ servicos
  -- Silvia            05/04/2021  Novo parametro flag_ctr_fisico
  -- Silvia            05/05/2021  Novos parametros p/ cadastro de pessoa (endereco)
  -- Silvia            12/04/2022  Novos parametros para responsavel
  -- Silvia            12/07/2022  Consistencia de responsavel obrigatorio
  -- Silvia            27/07/2022  Consistencia de cenario de acordo c/ status/etapa
  -- Silvia            09/08/2022  Enderecamento automatico de responsavel
  -- Ana Luiza         14/11/2023  Adicionado arquivo de aceite proposta
  -- Ana Luiza         19/12/2023  Adicionado verificacao para cond_pagamento e num_parc.
  -- Ana Luiza         19/02/2024  Adicionado consistencias de tipo_financeiro e job
  -- Joel Dias         21/02/2024  Não criar contrato e JobOP dependendo do Tipo de Negócio
  -- Ana Luiza         27/02/2024  Adicionado validacao caso nao encontre oport_servico
  -- Ana Luiza         10/04/2024  Ajustes para criacao de job
  -- Ana Luiza         23/04/2024  Ajuste Pais exterior
  -- Ana Luiza         29/05/2024  Insert automatico outra empresa responsavel em uma op
  -- Joel Dias         07/06/2024  separacao do loop de oport_servico com e sem empresa_resp
  -- Joel Dias         10/06/2024  inclusão de descrição no oport_servico e
  --                               abertura de serviços no contrato com o mesmo servico_id
  -- Ana Luiza         13/06/2024  Adicionado max no pessoa_id
  -- Joel Dias         13/06/2024  Adicao de unidade negocio no job
  -- Ana Luiza         11/07/2024  Montando data de inicio e fim de acordo com duracao de meses
  -- Ana Luiza         19/07/2024  Alterado nome da oportunidade
  -- Ana Luiza         30/08/2024  Ajustando divisor 0
  -- Ana Luiza         27/09/2024  Correcao para voltar nulo caso soma retorne vazia
  -- Ana Luiza         25/10/2024  Adicao de chave pix no job automatico
  -- Ana Luiza         18/12/2024  Criacao de parametro para controlar criacao de jobs
  -- Ana Luiza         09/01/2025  Implementacao da logica para controle de criacao jobs 
  -- Ana Luiza         16/01/2025  Joel especificou que sera considerado o parametro que vier     
  --                               na empresa vinculada na oportunidade
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id            IN NUMBER,
  p_empresa_id                   IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id              IN oportunidade.oportunidade_id%TYPE,
  p_cli_tipo_pessoa              IN VARCHAR2,
  p_cli_apelido                  IN VARCHAR2,
  p_cli_nome                     IN VARCHAR2,
  p_cli_produto                  IN VARCHAR2,
  p_cli_cnpj_cpf                 IN VARCHAR2,
  p_cli_endereco                 IN VARCHAR2,
  p_cli_num_ender                IN VARCHAR2,
  p_cli_compl_ender              IN VARCHAR2,
  p_cli_bairro                   IN VARCHAR2,
  p_cli_cep                      IN VARCHAR2,
  p_cli_cidade                   IN VARCHAR2,
  p_cli_uf                       IN VARCHAR2,
  p_cli_pais                     IN VARCHAR2,
  p_cli_email                    IN VARCHAR2,
  p_cli_ddd_telefone             IN VARCHAR2,
  p_cli_num_telefone             IN VARCHAR2,
  p_cli_nome_setor               IN VARCHAR2,
  p_int1_data                    IN VARCHAR2,
  p_int1_usuario_id              IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato            IN VARCHAR2,
  p_int1_descricao               IN interacao.descricao%TYPE,
  p_cenario_escolhido_id         IN cenario.cenario_id%TYPE,
  p_arquivo_prop_id              IN oportunidade.arquivo_prop_id%TYPE,
  p_arquivo_acei_id              IN oportunidade.arquivo_acei_id%TYPE,
  p_vetor_srv_cenario_servico_id IN VARCHAR2,
  p_vetor_srv_servico_id         IN VARCHAR2,
  p_vetor_srv_empresa_id         IN VARCHAR2,
  p_vetor_srv_emp_resp_id        IN VARCHAR2,
  p_vetor_srv_valor              IN VARCHAR2,
  p_vetor_srv_usu_resp_id        IN VARCHAR2,
  p_vetor_srv_uneg_resp_id       IN VARCHAR2,
  p_vetor_ctr_empresa_id         IN VARCHAR2,
  p_vetor_ctr_emp_resp_id        IN VARCHAR2,
  p_vetor_ctr_data_inicio        IN VARCHAR2,
  p_vetor_ctr_data_termino       IN VARCHAR2,
  p_vetor_ctr_flag_renovavel     IN VARCHAR2,
  p_vetor_ctr_flag_fisico        IN VARCHAR2,
  p_vetor_ender_empresas         IN VARCHAR2,
  p_vetor_ender_usuarios         IN VARCHAR2,
  p_vetor_ender_flag_resp        IN VARCHAR2,
  p_erro_cod                     OUT VARCHAR2,
  p_erro_msg                     OUT VARCHAR2
 ) IS
  v_qt                           INTEGER;
  v_exception                    EXCEPTION;
  v_tipo_conc                    oportunidade.tipo_conc%TYPE;
  v_numero_oport                 oportunidade.numero%TYPE;
  v_nome_oport                   oportunidade.nome%TYPE;
  v_status_oport                 oportunidade.status%TYPE;
  v_status_aux_oport_id          oportunidade.status_aux_oport_id%TYPE;
  v_status_aux_oport_aux_id      oportunidade.status_aux_oport_id%TYPE;
  v_valor_oportun                oportunidade.valor_oportun%TYPE;
  v_tipo_contrato_id             oportunidade.tipo_contrato_id%TYPE;
  v_cliente_id                   oportunidade.cliente_id%TYPE;
  v_produto_cliente_id           oportunidade.produto_cliente_id%TYPE;
  v_data_interacao1              interacao.data_interacao%TYPE;
  v_interacao_id                 interacao.interacao_id%TYPE;
  v_data_inicio                  contrato.data_inicio%TYPE;
  v_data_termino                 contrato.data_termino%TYPE;
  v_contrato_id                  contrato.contrato_id%TYPE;
  v_nome_contrato                contrato.nome%TYPE;
  v_cli_cnpj                     pessoa.cnpj%TYPE;
  v_cli_cpf                      pessoa.cpf%TYPE;
  v_cli_apelido                  pessoa.apelido%TYPE;
  v_cli_nome                     pessoa.nome%TYPE;
  v_cli_produto                  produto_cliente.nome%TYPE;
  v_cli_pais                     pessoa.pais%TYPE;
  v_cli_cep                      pessoa.cep%TYPE;
  v_apelido                      pessoa.apelido%TYPE;
  v_flag_pessoa_jur              pessoa.flag_pessoa_jur%TYPE;
  v_flag_sem_docum               pessoa.flag_sem_docum%TYPE;
  v_setor_id                     pessoa.setor_id%TYPE;
  v_tipo_pessoa_est_id           tipo_pessoa.tipo_pessoa_id%TYPE;
  v_empresa_id                   contrato.empresa_id%TYPE;
  v_emp_resp_id                  contrato.emp_resp_id%TYPE;
  v_flag_renovavel               VARCHAR2(100);
  v_flag_ctr_fisico              VARCHAR2(100);
  v_cenario_id                   cenario_empresa.cenario_id%TYPE;
  v_cenario_empresa_id           cenario_empresa.cenario_empresa_id%TYPE;
  v_servico_id                   oport_servico.servico_id%TYPE;
  v_valor_servico                oport_servico.valor_servico%TYPE;
  v_empresa_srv_id               oport_servico.empresa_id%TYPE;
  v_usuario_resp_id              oport_servico.usuario_resp_id%TYPE;
  v_unid_negocio_resp_id         oport_servico.unid_negocio_resp_id%TYPE;
  v_contrato_servico_id          contrato_servico.contrato_servico_id%TYPE;
  v_descricao                    contrato_servico.descricao%TYPE;
  v_nome_servico                 VARCHAR2(200);
  v_flag_ativo                   servico.flag_ativo%TYPE;
  v_delimitador                  CHAR(1);
  v_vetor_ctr_cenario_empresa_id VARCHAR2(2000);
  v_vetor_ctr_emp_resp_id        VARCHAR2(2000);
  v_vetor_ctr_data_inicio        VARCHAR2(2000);
  v_vetor_ctr_data_termino       VARCHAR2(2000);
  v_vetor_ctr_flag_renovavel     VARCHAR2(2000);
  v_vetor_ctr_flag_fisico        VARCHAR2(2000);
  v_data_inicio_char             VARCHAR2(20);
  v_data_termino_char            VARCHAR2(20);
  v_vetor_srv_cenario_servico_id VARCHAR2(2000);
  v_vetor_srv_servico_id         VARCHAR2(2000);
  v_vetor_srv_empresa_id         VARCHAR2(2000);
  v_vetor_srv_emp_resp_id        VARCHAR2(2000);
  v_vetor_srv_valor              VARCHAR2(2000);
  v_vetor_srv_usu_resp_id        VARCHAR2(2000);
  v_vetor_srv_uneg_resp_id       VARCHAR2(2000);
  v_vetor_ctr_empresa_id         VARCHAR2(2000);
  v_valor_char                   VARCHAR2(20);
  v_obriga_cli_completo          VARCHAR2(20);
  v_cli_flag_exterior            CHAR(1);
  v_flag_usar_servico            VARCHAR2(10);
  v_obriga_setor_cli             VARCHAR2(10);
  v_usa_resp_serv                VARCHAR2(10);
  v_obriga_resp_serv             VARCHAR2(10);
  v_lbl_un                       VARCHAR2(100);
  v_const_status_todos CONSTANT dicionario.codigo%TYPE := 'TODOS';
  v_flag_obriga_cenario    status_aux_oport.flag_obriga_cenario%TYPE;
  v_contrato_serv_valor_id contrato_serv_valor.contrato_serv_valor_id%TYPE;
  v_cenario_servico_id     cenario_servico.cenario_servico_id%TYPE;
  v_mes_ano_inicio         cenario_servico.mes_ano_inicio%TYPE;
  v_duracao_meses          cenario_servico.duracao_meses%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_tipo_financeiro_id     job.tipo_financeiro_id%TYPE;
  v_tipo_num_job           job.tipo_num_job%TYPE;
  v_tipo_job_id            tipo_job.tipo_job_id%TYPE;
  v_contrato_numero        contrato.numero%TYPE;
  v_unidade_negocio_id     job.unidade_negocio_id%TYPE;
  v_num_parcelas           cenario.num_parcelas%TYPE;
  v_cond_pagamento         cenario.cond_pagamento%TYPE;
  v_tipo_negocio           dicionario.codigo%TYPE;
  v_flag_cria_contrato     CHAR(1);
  v_nome_empresa           empresa.nome%TYPE;
  --ALCBO_230424
  v_pessoa_id              pessoa.pessoa_id%TYPE;
  v_new_cliente_id         oportunidade.cliente_id%TYPE;
  v_new_produto_cliente_id produto_cliente.produto_cliente_id%TYPE;
  --
  v_cod_job          pessoa.cod_job%TYPE;
  v_num_primeiro_job pessoa.num_primeiro_job%TYPE;
  --ALCBO_110724
  v_data_inicio_cs contrato_servico.data_inicio%TYPE;
  v_data_fim_cs    contrato_servico.data_inicio%TYPE;
  v_chave_pix      pessoa.chave_pix%TYPE;
  --ALBCO_181224
  v_qtd_jobs_ganhar_oport VARCHAR2(100);
  v_job_ja_criado         CHAR(1);
  v_empresa_id_op         oportunidade.empresa_id%TYPE;
  --
  -- servicos do cenario
  CURSOR c_se IS
   SELECT cs.servico_id,
          cs.preco_final,
          se.nome AS nome_servico,
          cs.descricao
     FROM cenario_servico cs,
          servico         se
    WHERE cs.cenario_id = p_cenario_escolhido_id
      AND cs.servico_id = se.servico_id;
  --
  -- valores dos servicos da empresa operacional
  CURSOR c_cs IS
   SELECT o.servico_id,
          SUM(o.valor_servico) AS valor_servico,
          o.usuario_resp_id,
          o.unid_negocio_resp_id,
          g.nome || '/' || s.nome AS servico_nome,
          o.descricao
     FROM oport_servico o
    INNER JOIN cenario_servico cs
       ON cs.servico_id = o.servico_id
    INNER JOIN servico s
       ON s.servico_id = cs.servico_id
    INNER JOIN grupo_servico g
       ON g.grupo_servico_id = s.grupo_servico_id
    WHERE cs.cenario_id = p_cenario_escolhido_id
      AND o.oportunidade_id = p_oportunidade_id
    GROUP BY o.servico_id,
             o.usuario_resp_id,
             o.unid_negocio_resp_id,
             g.nome,
             s.nome,
             o.descricao;
  /*
  SELECT cs.servico_id,
         cs.valor_servico,
         cs.usuario_resp_id,
         cs.unid_negocio_resp_id,
         gs.nome || '/' || se.nome AS servico_nome
    FROM cenario_servico cs
    LEFT JOIN servico se
      ON cs.servico_id = se.servico_id
    LEFT JOIN grupo_servico gs
      ON se.grupo_servico_id = gs.grupo_servico_id
   WHERE cs.cenario_id = p_cenario_escolhido_id;*/
  --
  CURSOR c_op IS
   SELECT cs.cenario_servico_id,
          o.emp_resp_id,
          o.servico_id,
          o.descricao,
          o.valor_servico,
          o.usuario_resp_id,
          o.unid_negocio_resp_id,
          g.nome || '/' || s.nome AS servico_nome
     FROM oport_servico o
    INNER JOIN cenario_servico cs
       ON cs.servico_id = o.servico_id
      AND o.descricao = cs.descricao
    INNER JOIN servico s
       ON s.servico_id = cs.servico_id
    INNER JOIN grupo_servico g
       ON g.grupo_servico_id = s.grupo_servico_id
    WHERE cs.cenario_id = p_cenario_escolhido_id
      AND o.oportunidade_id = p_oportunidade_id;
  --
 BEGIN
  v_qt                  := 0;
  v_tipo_conc           := 'GAN';
  v_obriga_cli_completo := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_CLIOPO_COMPLETO');
  v_flag_usar_servico   := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_CONTRATO');
  v_obriga_setor_cli    := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_SETOR_CLIENTE');
  v_usa_resp_serv       := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_RESP_SERV_OPORT');
  v_lbl_un              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  v_obriga_resp_serv    := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_RESP_SERV_OPORT');
  --ALCBO_160125
  SELECT empresa_id
    INTO v_empresa_id_op
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  v_qtd_jobs_ganhar_oport := empresa_pkg.parametro_retornar(v_empresa_id_op,
                                                            'QTD_JOBS_GANHAR_OPORT');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CONC',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.nome,
         op.status,
         op.tipo_contrato_id,
         op.cliente_id,
         op.produto_cliente_id,
         op.status_aux_oport_id
    INTO v_numero_oport,
         v_nome_oport,
         v_status_oport,
         v_tipo_contrato_id,
         v_cliente_id,
         v_produto_cliente_id,
         v_status_aux_oport_id
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  --v_nome_contrato := 'Criado a partir da Oportunidade ' || v_numero_oport;
  v_nome_contrato := v_nome_oport;
  /*
  a partir do release 172 passamos a prencher a descrição de
  oport_servico com cenario_servico
  v_descricao     := 'Incluído pela Oportunidade ' || v_numero_oport;
  */
  --
  SELECT nome
    INTO v_cli_produto
    FROM produto_cliente
   WHERE produto_cliente_id = v_produto_cliente_id;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_est_id
    FROM tipo_pessoa
   WHERE codigo = 'ESTRANGEIRO';
  --
  IF TRIM(p_cli_tipo_pessoa) IS NULL OR p_cli_tipo_pessoa NOT IN ('F', 'J')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de pessoa inválido (' || p_cli_tipo_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cli_tipo_pessoa = 'J'
  THEN
   v_flag_pessoa_jur := 'S';
  ELSE
   v_flag_pessoa_jur := 'N';
  END IF;
  --
  v_cli_flag_exterior := 'N';
  IF nvl(upper(TRIM(p_cli_pais)), 'BRASIL') <> 'BRASIL'
  THEN
   v_cli_flag_exterior := 'S';
  END IF;
  --
  v_cli_apelido := TRIM(p_cli_apelido);
  v_cli_nome    := TRIM(p_cli_nome);
  v_cli_produto := TRIM(p_cli_produto);
  v_cli_pais    := TRIM(upper(acento_retirar(p_cli_pais)));
  --
  IF v_cli_apelido IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Nome Fantasia/Apelido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_cli_apelido) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Nome Fantasia/Apelido não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cli_nome IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Razão Social/Nome Completo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_cli_nome) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Razão Social/Nome Completo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cli_produto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Produto do Cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_cli_produto) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Produto do Cliente não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE pessoa_id = v_cliente_id
     AND nome = v_cli_produto
     AND produto_cliente_id <> v_produto_cliente_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe outro produto do cliente cadastrado com esse nome.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pessoa_jur = 'S' AND TRIM(p_cli_cnpj_cpf) IS NOT NULL
  THEN
   IF cnpj_pkg.validar(p_cli_cnpj_cpf, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CNPJ inválido (' || p_cli_cnpj_cpf || ').';
    RAISE v_exception;
   END IF;
   --
   v_cli_cnpj := cnpj_pkg.converter(p_cli_cnpj_cpf, p_empresa_id);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE empresa_id = p_empresa_id
      AND cnpj = v_cli_cnpj
      AND pessoa_id <> v_cliente_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe outra pessoa cadastrada com esse CNPJ.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_pessoa_jur = 'N' AND TRIM(p_cli_cnpj_cpf) IS NOT NULL
  THEN
   IF cpf_pkg.validar(p_cli_cnpj_cpf, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CPF inválido (' || p_cli_cnpj_cpf || ').';
    RAISE v_exception;
   END IF;
   --
   v_cli_cpf := cpf_pkg.converter(p_cli_cnpj_cpf, p_empresa_id);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE empresa_id = p_empresa_id
      AND cpf = v_cli_cpf
      AND pessoa_id <> v_cliente_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe outra pessoa cadastrada com esse CPF.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_cli_flag_exterior = 'S' AND TRIM(p_cli_cnpj_cpf) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para cliente no exterior, o CNPJ/CPF não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF v_cli_flag_exterior = 'N' AND TRIM(p_cli_cnpj_cpf) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O CNPJ/CPF deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF v_obriga_setor_cli = 'S' AND TRIM(p_cli_nome_setor) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Setor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cli_nome_setor) IS NOT NULL
  THEN
   SELECT MAX(setor_id)
     INTO v_setor_id
     FROM setor
    WHERE empresa_id = p_empresa_id
      AND upper(nome) = upper(TRIM(p_cli_nome_setor));
   --
   IF v_setor_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Setor não existe (' || p_cli_nome_setor || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_obriga_cli_completo = 'S'
  THEN
   IF TRIM(p_cli_endereco) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Endereço é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cli_bairro) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Bairro é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cli_uf) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da UF é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cli_cidade) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Município é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cli_cep) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do CEP é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cli_cep) IS NOT NULL AND (v_cli_pais IS NULL OR upper(v_cli_pais) = 'BRASIL')
  THEN
   IF cep_pkg.validar(p_cli_cep) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_cli_cep := cep_pkg.converter(TRIM(p_cli_cep));
  --
  IF TRIM(p_cli_uf) IS NOT NULL AND (v_cli_pais IS NULL OR upper(v_cli_pais) = 'BRASIL')
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_cli_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cli_uf) IS NOT NULL AND TRIM(p_cli_cidade) IS NOT NULL AND
     (v_cli_pais IS NULL OR upper(v_cli_pais) = 'BRASIL')
  THEN
   IF cep_pkg.municipio_validar(p_cli_uf, p_cli_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do endereço inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_cli_pais IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do País é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_cli_pais) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O País não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pais
   WHERE upper(nome) = upper(v_cli_pais);
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'País inválido (' || v_cli_pais || ').';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_cli_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
  --
  v_flag_sem_docum := 'N';
  IF TRIM(p_cli_cnpj_cpf) IS NULL
  THEN
   v_flag_sem_docum := 'S';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do cliente
  ------------------------------------------------------------
  UPDATE pessoa
     SET apelido         = v_cli_apelido,
         nome            = v_cli_nome,
         flag_pessoa_jur = v_flag_pessoa_jur,
         cnpj            = v_cli_cnpj,
         cpf             = v_cli_cpf,
         pais            = v_cli_pais,
         flag_sem_docum  = v_flag_sem_docum,
         endereco        = TRIM(p_cli_endereco),
         num_ender       = TRIM(p_cli_num_ender),
         compl_ender     = TRIM(p_cli_compl_ender),
         bairro          = TRIM(p_cli_bairro),
         cep             = v_cli_cep,
         uf              = TRIM(p_cli_uf),
         cidade          = TRIM(p_cli_cidade),
         email           = TRIM(p_cli_email),
         ddd_telefone    = TRIM(p_cli_ddd_telefone),
         num_telefone    = TRIM(p_cli_num_telefone),
         setor_id        = v_setor_id
   WHERE pessoa_id = v_cliente_id;
  --
  UPDATE produto_cliente
     SET nome = v_cli_produto
   WHERE produto_cliente_id = v_produto_cliente_id;
  --
  IF v_cli_flag_exterior = 'N'
  THEN
   -- deleta eventual registro de pessoa no exterior
   DELETE FROM tipific_pessoa tp
    WHERE tp.pessoa_id = v_cliente_id
      AND EXISTS (SELECT 1
             FROM tipo_pessoa ti
            WHERE ti.codigo = 'ESTRANGEIRO'
              AND ti.tipo_pessoa_id = tp.tipo_pessoa_id);
  ELSE
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa
    WHERE pessoa_id = v_cliente_id
      AND tipo_pessoa_id = v_tipo_pessoa_est_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO tipific_pessoa
     (pessoa_id,
      tipo_pessoa_id)
    VALUES
     (v_cliente_id,
      v_tipo_pessoa_est_id);
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_int1_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da Interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int1_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da Interação inválida (' || p_int1_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao1 := data_converter(p_int1_data);
  --
  IF nvl(p_int1_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Autor/Responsável pela interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Meio de Contato da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_meio_contato', p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Meio de Contato inválido (' || p_int1_meio_contato || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_int1_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição/Resumo da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- testa obrigatoriedade do cenario no status atual
  SELECT nvl(MAX(flag_obriga_cenario), 'N')
    INTO v_flag_obriga_cenario
    FROM status_aux_oport
   WHERE status_aux_oport_id = v_status_aux_oport_id;
  --
  IF v_flag_obriga_cenario = 'S' AND nvl(p_cenario_escolhido_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Cenário Escolhido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- descobre o status estendido/etapa padrao destino
  SELECT MAX(status_aux_oport_id)
    INTO v_status_aux_oport_aux_id
    FROM status_aux_oport
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = 'CONC'
     AND flag_padrao = 'S';
  --
  IF v_status_aux_oport_aux_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão não encontrado para essa transição.';
   RAISE v_exception;
  END IF;
  --
  -- testa obrigatoriedade do cenario no status destino
  SELECT nvl(MAX(flag_obriga_cenario), 'N')
    INTO v_flag_obriga_cenario
    FROM status_aux_oport
   WHERE status_aux_oport_id = v_status_aux_oport_aux_id;
  --
  IF v_flag_obriga_cenario = 'S' AND nvl(p_cenario_escolhido_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Cenário Escolhido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_arquivo_prop_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Arquivo da Proposta é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_141123
  IF nvl(p_arquivo_acei_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Arquivo Aceite da Proposta é obrigatório.';
   RAISE v_exception;
  END IF;
  -- recupera o valor do cenario escolhido
  SELECT SUM(preco_final)
    INTO v_valor_oportun
    FROM cenario_servico
   WHERE cenario_id = p_cenario_escolhido_id;
  --
  IF nvl(instr(p_vetor_ender_flag_resp, 'S'), 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Responsável não foi indicado.';
   RAISE v_exception;
  END IF;
  --ALCBO_191223
  SELECT num_parcelas,
         cond_pagamento
    INTO v_num_parcelas,
         v_cond_pagamento
    FROM cenario
   WHERE cenario_id = p_cenario_escolhido_id
     AND oportunidade_id = p_oportunidade_id;
  --
  --
  IF TRIM(v_num_parcelas) IS NULL AND TRIM(v_cond_pagamento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Os campos Número de Parcelas (Provisão) e Condição de Pagamento (vezes) não estão preenchidos no Cenário escolhido. Seu preenchimento é necessário para a conclusão da Oportunidade.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_num_parcelas) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Número de Parcelas (Provisão) não está preenchido no Cenário escolhido. Seu preenchimento é necessário para a conclusão da Oportunidade.';
   RAISE v_exception;
  END IF;
  --
  --
  IF TRIM(v_cond_pagamento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Condição de Pagamento (vezes) não está preenchido no Cenário escolhido. Seu preenchimento é necessário para a conclusão da Oportunidade.';
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_obriga_cli_completo = 'S'
  THEN
   IF pessoa_pkg.dados_integr_verificar(v_cliente_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para se indicar a Oportunidade como Ganha, é ' ||
                  'necessário que as informações do Cliente estejam ' ||
                  'completas (CNPJ e endereço).';
    RAISE v_exception;
   END IF;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            v_cliente_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- desmarca cenario padrao
  UPDATE cenario
     SET flag_padrao = 'N'
   WHERE oportunidade_id = p_oportunidade_id;
  --
  -- torna o cenario escolhido padrao
  UPDATE cenario
     SET flag_padrao = 'S'
   WHERE cenario_id = p_cenario_escolhido_id;
  --
  SELECT seq_interacao.nextval
    INTO v_interacao_id
    FROM dual;
  --
  INSERT INTO interacao
   (interacao_id,
    oportunidade_id,
    usuario_resp_id,
    data_entrada,
    data_interacao,
    descricao,
    meio_contato,
    perc_prob_fech,
    data_prov_fech,
    usuario_prox_int_id,
    data_prox_int,
    desc_prox_int,
    status_aux_oport_id)
  VALUES
   (v_interacao_id,
    p_oportunidade_id,
    p_int1_usuario_id,
    SYSDATE,
    v_data_interacao1,
    p_int1_descricao,
    p_int1_meio_contato,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    v_status_aux_oport_id);
  --
  UPDATE oportunidade
     SET cenario_escolhido_id = p_cenario_escolhido_id,
         valor_oportun        = v_valor_oportun,
         arquivo_prop_id      = p_arquivo_prop_id,
         arquivo_acei_id      = p_arquivo_acei_id
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- enderecamento do autor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_int1_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int1_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      p_oportunidade_id,
                                      p_int1_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Oportunidade Ganha',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- vetores de distribuicao dos servicos
  ------------------------------------------------------------
  v_delimitador                  := '|';
  v_vetor_srv_cenario_servico_id := TRIM(p_vetor_srv_cenario_servico_id);
  v_vetor_srv_servico_id         := TRIM(p_vetor_srv_servico_id);
  v_vetor_srv_empresa_id         := TRIM(p_vetor_srv_empresa_id);
  v_vetor_srv_emp_resp_id        := TRIM(p_vetor_srv_emp_resp_id);
  v_vetor_srv_valor              := TRIM(p_vetor_srv_valor);
  v_vetor_srv_usu_resp_id        := TRIM(p_vetor_srv_usu_resp_id);
  v_vetor_srv_uneg_resp_id       := TRIM(p_vetor_srv_uneg_resp_id);
  --
  WHILE nvl(length(rtrim(v_vetor_srv_servico_id)), 0) > 0
  LOOP
   v_cenario_servico_id   := nvl(to_number(prox_valor_retornar(v_vetor_srv_cenario_servico_id,
                                                               v_delimitador)),
                                 0);
   v_servico_id           := nvl(to_number(prox_valor_retornar(v_vetor_srv_servico_id,
                                                               v_delimitador)),
                                 0);
   v_empresa_srv_id       := nvl(to_number(prox_valor_retornar(v_vetor_srv_empresa_id,
                                                               v_delimitador)),
                                 0);
   v_emp_resp_id          := nvl(to_number(prox_valor_retornar(v_vetor_srv_emp_resp_id,
                                                               v_delimitador)),
                                 0);
   v_valor_char           := prox_valor_retornar(v_vetor_srv_valor, v_delimitador);
   v_usuario_resp_id      := nvl(to_number(prox_valor_retornar(v_vetor_srv_usu_resp_id,
                                                               v_delimitador)),
                                 0);
   v_unid_negocio_resp_id := nvl(to_number(prox_valor_retornar(v_vetor_srv_uneg_resp_id,
                                                               v_delimitador)),
                                 0);
   --
   SELECT g.nome || '/' || s.nome,
          s.flag_ativo
     INTO v_nome_servico,
          v_flag_ativo
     FROM servico s
    INNER JOIN grupo_servico g
       ON g.grupo_servico_id = s.grupo_servico_id
    WHERE s.servico_id = v_servico_id;
   --
   IF v_nome_servico IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe (' || to_char(v_servico_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_ativo = 'N'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível concluir pois o produto ' || v_nome_servico || ' está inativo.';
    RAISE v_exception;
   END IF;
   --
   IF v_emp_resp_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da empresa responsável pelo produto ' || v_nome_servico ||
                  ' é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = v_emp_resp_id
      AND empresa_id = v_empresa_srv_id
      AND flag_emp_resp = 'S';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável pelo produto ' || v_nome_servico || ' não existe (' ||
                  to_char(v_emp_resp_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_valor_char) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do valor do produto ' || v_nome_servico || ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_valor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do produto ' || v_nome_servico || ' inválido (' || v_valor_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_servico := nvl(round(numero_converter(v_valor_char), 2), 0);
   --
   IF v_usa_resp_serv = 'S' AND v_obriga_resp_serv = 'S' AND nvl(v_usuario_resp_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Responsável pelo produto é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_unid_negocio_resp_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM unidade_negocio
     WHERE unidade_negocio_id = v_unid_negocio_resp_id
       AND empresa_id = v_empresa_srv_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := v_lbl_un || ' não existe ou não pertence a essa empresa (' ||
                   to_char(v_unid_negocio_resp_id) || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   SELECT descricao
     INTO v_descricao
     FROM cenario_servico
    WHERE cenario_servico_id = v_cenario_servico_id;
   --
   INSERT INTO oport_servico
    (oport_servico_id,
     oportunidade_id,
     empresa_id,
     emp_resp_id,
     servico_id,
     descricao,
     usuario_resp_id,
     unid_negocio_resp_id,
     valor_servico)
   VALUES
    (seq_oport_servico.nextval,
     p_oportunidade_id,
     v_empresa_srv_id,
     v_emp_resp_id,
     v_servico_id,
     v_descricao,
     zvl(v_usuario_resp_id, NULL),
     zvl(v_unid_negocio_resp_id, NULL),
     v_valor_servico);
   --
   -- enderecamento automatico do usuario responsavel
   --
   IF nvl(v_usuario_resp_id, 0) > 0
   THEN
    -- endereca o usuario responsavel.
    SELECT apelido
      INTO v_apelido
      FROM pessoa
     WHERE usuario_id = v_usuario_resp_id;
    --
    -- a subrotina marca como: com co-ender, sem pula notif
    oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                       'N',
                                       'S',
                                       'N',
                                       p_empresa_id,
                                       p_oportunidade_id,
                                       v_usuario_resp_id,
                                       v_apelido || ' endereçado automaticamente (responsável)',
                                       'Oportunidade ganha',
                                       p_erro_cod,
                                       p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  SELECT nvl(SUM(preco_final), 0)
    INTO v_valor_servico
    FROM cenario_servico
   WHERE cenario_id = p_cenario_escolhido_id;
  --
  IF v_valor_servico <> v_valor_oportun
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A soma dos valores dos produtos distribuídos nas ' ||
                 'empresas deve bater com o valor total dos produtos (' ||
                 moeda_mostrar(v_valor_oportun, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos rateios dos servicos
  ------------------------------------------------------------
  FOR r_se IN c_se
  LOOP
   --ALCBO_270924
   SELECT nvl(SUM(valor_servico), 0)
     INTO v_valor_servico
     FROM oport_servico
    WHERE oportunidade_id = p_oportunidade_id
      AND servico_id = r_se.servico_id
      AND descricao = r_se.descricao;
   --
   IF v_valor_servico <> r_se.preco_final
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores do produto ' || r_se.nome_servico || ' distribuídos nas ' ||
                  'empresas deve bater com o valor total desse produto (' ||
                  moeda_mostrar(r_se.preco_final, 'S') || ').';
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- cria contratos automaticamente
  ------------------------------------------------------------
  --
  --verificar se o tipo de negócio da oportunidade permite a criação de contrato
  SELECT tipo_negocio
    INTO v_tipo_negocio
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF substr(v_tipo_negocio, 1, 3) = 'SCT'
  THEN
   v_flag_cria_contrato := 'N';
  ELSE
   v_flag_cria_contrato := 'S';
  END IF;
  --
  IF v_flag_cria_contrato = 'S'
  THEN
   --
   v_delimitador              := '|';
   v_vetor_ctr_empresa_id     := TRIM(p_vetor_ctr_empresa_id);
   v_vetor_ctr_emp_resp_id    := TRIM(p_vetor_ctr_emp_resp_id);
   v_vetor_ctr_data_inicio    := TRIM(p_vetor_ctr_data_inicio);
   v_vetor_ctr_data_termino   := TRIM(p_vetor_ctr_data_termino);
   v_vetor_ctr_flag_renovavel := TRIM(p_vetor_ctr_flag_renovavel);
   v_vetor_ctr_flag_fisico    := TRIM(p_vetor_ctr_flag_fisico);
   v_vetor_srv_emp_resp_id    := TRIM(p_vetor_srv_emp_resp_id); --emp_responsavel
  
   --
   -- loop por cenario no vetor
   WHILE nvl(length(rtrim(v_vetor_ctr_empresa_id)), 0) > 0
   LOOP
    v_cenario_empresa_id := to_number(prox_valor_retornar(v_vetor_ctr_empresa_id, v_delimitador));
    v_emp_resp_id        := to_number(prox_valor_retornar(v_vetor_ctr_emp_resp_id, v_delimitador));
    v_data_inicio_char   := prox_valor_retornar(v_vetor_ctr_data_inicio, v_delimitador);
    v_data_termino_char  := prox_valor_retornar(v_vetor_ctr_data_termino, v_delimitador);
    v_flag_renovavel     := prox_valor_retornar(v_vetor_ctr_flag_renovavel, v_delimitador);
    v_flag_ctr_fisico    := prox_valor_retornar(v_vetor_ctr_flag_fisico, v_delimitador);
   
    v_emp_resp_id := nvl(v_emp_resp_id, 0);
   
    IF TRIM(v_data_inicio_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do início da vigência do contrato é obrigatório. ' ||
                   'empresa->' || v_cenario_empresa_id || ' data->' || p_vetor_ctr_data_inicio;
     RAISE v_exception;
    END IF;
    --
    IF data_validar(v_data_inicio_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data de início da vigência do contrato inválida (' || v_data_inicio_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_data_termino_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do término da vigência do contrato é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF data_validar(v_data_termino_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data de término da vigência do contrato inválida (' || v_data_termino_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF flag_validar(v_flag_renovavel) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Flag renovável inválido (' || v_flag_renovavel || ').';
     RAISE v_exception;
    END IF;
    --
    IF flag_validar(v_flag_ctr_fisico) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Flag contrato jurídico inválido (' || v_flag_ctr_fisico || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_inicio  := data_converter(v_data_inicio_char);
    v_data_termino := data_converter(v_data_termino_char);
    --
    --aqui retirar esta consulta
    /*SELECT MAX(empresa_id),
          MAX(cenario_id)
     INTO v_empresa_id,
          v_cenario_id
     FROM cenario_empresa
    WHERE cenario_empresa_id = v_cenario_empresa_id;
    */
    --
    v_empresa_id := v_cenario_empresa_id;
    v_cenario_id := p_cenario_escolhido_id;
    --
    IF v_flag_usar_servico = 'N'
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM pessoa
      WHERE pessoa_id = v_emp_resp_id
        AND empresa_id = v_empresa_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Essa empresa responsável (' || to_char(v_emp_resp_id) ||
                    ') não existe na empresa operacional (' || to_char(v_empresa_id) || ').';
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- verifica se ja existe contrato associado a
    -- oportunidade nessa empresa
    SELECT MAX(ct.contrato_id)
      INTO v_contrato_id
      FROM oport_contrato oc,
           contrato       ct
     WHERE oc.oportunidade_id = p_oportunidade_id
       AND oc.contrato_id = ct.contrato_id
       AND ct.empresa_id = v_empresa_id;
    --
    --ALCBO_290524 - INSERT AUTOMATICO PARA EMPRESA RESPONSAVEL
    --verifica se ja possui um padrao de nome no job
    SELECT MAX(upper(cod_job))
      INTO v_cod_job
      FROM pessoa
     WHERE pessoa_id = v_cliente_id;
    --
    SELECT MAX(nvl(num_primeiro_job, 1))
      INTO v_num_primeiro_job
      FROM pessoa
     WHERE pessoa_id = v_cliente_id;
    --ALCBO_251024
    SELECT MAX(TRIM(chave_pix))
      INTO v_chave_pix
      FROM pessoa
     WHERE pessoa_id = v_cliente_id;
    --
    IF v_cod_job IS NULL
    THEN
     v_cod_job := '0001';
    END IF;
    --
    IF v_num_primeiro_job IS NULL
    THEN
     v_num_primeiro_job := '0001';
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM pessoa
     WHERE empresa_id = v_empresa_id
       AND pessoa_id = v_cliente_id;
    --
    IF v_qt = 0
    THEN
     SELECT seq_pessoa.nextval
       INTO v_new_cliente_id
       FROM dual;
     --
     INSERT INTO pessoa
      (pessoa_id,
       empresa_id,
       apelido,
       nome,
       flag_pessoa_jur,
       cnpj,
       cpf,
       pais,
       flag_sem_docum,
       endereco,
       num_ender,
       compl_ender,
       bairro,
       cep,
       uf,
       cidade,
       email,
       ddd_telefone,
       num_telefone,
       setor_id,
       flag_ativo,
       cod_job,
       num_primeiro_job,
       chave_pix)
     VALUES
      (v_new_cliente_id,
       v_empresa_id, --EMPRESA_ID
       v_cli_apelido,
       v_cli_nome,
       v_flag_pessoa_jur,
       v_cli_cnpj,
       v_cli_cpf,
       v_cli_pais,
       v_flag_sem_docum,
       TRIM(p_cli_endereco),
       TRIM(p_cli_num_ender),
       TRIM(p_cli_compl_ender),
       TRIM(p_cli_bairro),
       v_cli_cep,
       TRIM(p_cli_uf),
       TRIM(p_cli_cidade),
       TRIM(p_cli_email),
       TRIM(p_cli_ddd_telefone),
       TRIM(p_cli_num_telefone),
       v_setor_id,
       'S',
       v_cod_job,
       v_num_primeiro_job,
       TRIM(v_chave_pix)); --ALCBO_251024
    
     SELECT seq_produto_cliente.nextval
       INTO v_new_produto_cliente_id
       FROM dual;
    
     INSERT INTO produto_cliente
      (produto_cliente_id,
       pessoa_id,
       nome)
     VALUES
      (v_new_produto_cliente_id,
       v_new_cliente_id,
       v_cli_produto);
    END IF;
    --
    IF v_contrato_id IS NULL
    THEN
     --criar contrato
     contrato_pkg.adicionar_simples(p_usuario_sessao_id,
                                    v_empresa_id, --ALCBO_050424 --v_empresa_id
                                    v_tipo_contrato_id,
                                    v_emp_resp_id,
                                    v_nome_contrato,
                                    v_flag_pessoa_jur,
                                    v_cli_flag_exterior,
                                    v_flag_sem_docum,
                                    v_cli_apelido,
                                    v_cli_nome,
                                    v_cli_cnpj,
                                    v_cli_cpf,
                                    TRIM(p_cli_endereco),
                                    TRIM(p_cli_num_ender),
                                    TRIM(p_cli_compl_ender),
                                    TRIM(p_cli_bairro),
                                    v_cli_cep,
                                    TRIM(p_cli_cidade),
                                    TRIM(p_cli_uf),
                                    v_cli_pais,
                                    TRIM(p_cli_email),
                                    TRIM(p_cli_ddd_telefone),
                                    TRIM(p_cli_num_telefone),
                                    TRIM(p_cli_nome_setor),
                                    v_data_inicio_char,
                                    v_data_termino_char,
                                    v_flag_renovavel,
                                    v_flag_ctr_fisico,
                                    p_vetor_ender_empresas,
                                    p_vetor_ender_usuarios,
                                    p_vetor_ender_flag_resp,
                                    v_contrato_id,
                                    p_erro_cod,
                                    p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     SELECT numero
       INTO v_contrato_numero
       FROM contrato
      WHERE contrato_id = v_contrato_id;
     -- vincula o contrato a oportunidade
     INSERT INTO oport_contrato
      (oportunidade_id,
       contrato_id)
     VALUES
      (p_oportunidade_id,
       v_contrato_id);
     --
     --vincula a tabela de modalidade de contratação instanciada no cenario
     --ao contrato aberto acima
     UPDATE cenario_mod_contr
        SET contrato_id = v_contrato_id
      WHERE cenario_id = p_cenario_escolhido_id;
     -- copia os valores dos servicos da empresa
     -- operacional definidos na oportunidade, para
     -- o contrato.
     --ALCBO_270224
     SELECT MAX(oport_servico_id)
       INTO v_qt
       FROM oport_servico o
      INNER JOIN servico s
         ON s.servico_id = o.servico_id
      INNER JOIN grupo_servico g
         ON g.grupo_servico_id = s.grupo_servico_id
      WHERE o.oportunidade_id = p_oportunidade_id
        AND o.empresa_id = v_empresa_id;
     --ALCBO_270224
     IF v_qt IS NOT NULL
     THEN
      FOR r_op IN c_op
      LOOP
       --
       SELECT cenario_servico_id,
              mes_ano_inicio,
              duracao_meses,
              descricao
         INTO v_cenario_servico_id,
              v_mes_ano_inicio,
              v_duracao_meses,
              v_descricao
         FROM cenario_servico
        WHERE cenario_id = p_cenario_escolhido_id
          AND servico_id = r_op.servico_id
          AND descricao = r_op.descricao;
       --
       SELECT COUNT(*)
         INTO v_qt
         FROM contrato_servico
        WHERE contrato_id = v_contrato_id
          AND servico_id = r_op.servico_id
          AND descricao = r_op.descricao;
       --
       IF v_qt = 0
       THEN
        SELECT seq_contrato_servico.nextval
          INTO v_contrato_servico_id
          FROM dual;
        --ALCBO_110724
        SELECT MAX(mes_ano_inicio) AS inicio,
               add_months(MAX(add_months(mes_ano_inicio, duracao_meses) - 1), 0) AS termino
          INTO v_data_inicio_cs,
               v_data_fim_cs
          FROM cenario_servico
         WHERE cenario_id = p_cenario_escolhido_id
           AND cenario_servico_id = r_op.cenario_servico_id;
        --
        INSERT INTO contrato_servico
         (contrato_servico_id,
          contrato_id,
          servico_id,
          data_inicio,
          data_termino,
          descricao)
        VALUES
         (v_contrato_servico_id,
          v_contrato_id,
          r_op.servico_id,
          v_data_inicio_cs,
          v_data_fim_cs, --ALCBO_110724 | antes -> v_data_inicio,v_data_termino
          r_op.descricao);
       END IF;
       --
       --inserção dos serviços do cenário ganho no contrato
       INSERT INTO contrato_serv_valor
        (contrato_serv_valor_id,
         contrato_servico_id,
         emp_resp_id,
         data_refer,
         valor_servico,
         usuario_resp_id,
         unid_negocio_resp_id,
         flag_oport)
       VALUES
        (seq_contrato_serv_valor.nextval,
         v_contrato_servico_id,
         r_op.emp_resp_id,
         trunc(SYSDATE),
         r_op.valor_servico,
         r_op.usuario_resp_id,
         r_op.unid_negocio_resp_id,
         'S');
       --
      END LOOP;
      FOR r_cs IN c_cs
      LOOP
       --ALCBO_190224
       SELECT COUNT(*)
         INTO v_qt
         FROM tipo_financeiro
        WHERE empresa_id = v_empresa_id
          AND flag_padrao = 'S';
       --
       IF v_qt = 0
       THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Não existe um Tipo Financeiro padrão cadastrado
                                  para essa empresa.';
        RAISE v_exception;
       END IF;
       --ALCBO_190224
       SELECT COUNT(*)
         INTO v_qt
         FROM tipo_job
        WHERE flag_padrao = 'S'
          AND empresa_id = v_empresa_id;
       --
       IF v_qt = 0
       THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Não existe um Job padrão cadastrado
                                  para essa empresa.';
        RAISE v_exception;
       END IF;
       --recupera tipo de job padrão para o novo job
       SELECT tipo_job_id
         INTO v_tipo_job_id
         FROM tipo_job
        WHERE flag_padrao = 'S'
          AND empresa_id = v_empresa_id;
       --recupera tipo financeiro padrão para o novo job
       SELECT tipo_financeiro_id
         INTO v_tipo_financeiro_id
         FROM tipo_financeiro
        WHERE empresa_id = v_empresa_id
          AND flag_padrao = 'S';
       --
       --
       --
       --
       --ALCBO_230424
       SELECT nome
         INTO v_nome_empresa
         FROM empresa
        WHERE empresa_id = v_empresa_id;
       --
       IF v_cli_flag_exterior = 'S'
       THEN
        SELECT COUNT(*)
          INTO v_qt
          FROM pessoa pe
         INNER JOIN tipific_pessoa tip
            ON tip.pessoa_id = pe.pessoa_id
         INNER JOIN tipo_pessoa tp
            ON tip.tipo_pessoa_id = tp.tipo_pessoa_id
         WHERE tp.codigo = 'ESTRANGEIRO'
           AND pe.empresa_id = v_empresa_id
           AND pe.nome = TRIM(v_cli_nome); --pega pelo apelido(sem cnpj/cpf)
       
        IF v_qt = 0
        THEN
         p_erro_cod := '90000';
         p_erro_msg := 'O cliente ' || v_cli_nome || ' não foi localizado na Empresa ' ||
                       v_nome_empresa;
         RAISE v_exception;
        END IF;
        -- Obter o pessoa_id se o cliente existir
        SELECT MAX(pessoa_id) --ALCBO_130624
          INTO v_cliente_id
          FROM pessoa pe
         WHERE pe.nome = TRIM(v_cli_nome)
           AND pe.empresa_id = v_empresa_id;
       ELSE
        -- v_cli_flag_exterior = N
        SELECT COUNT(*)
          INTO v_qt
          FROM pessoa pe
         WHERE (pe.cnpj = v_cli_cnpj OR pe.cpf = v_cli_cpf)
           AND pe.empresa_id = v_empresa_id;
        --
        IF v_qt = 0
        THEN
         p_erro_cod := '90000';
         p_erro_msg := 'O cliente ' || v_cli_nome || ' que possui o CNPJ ' || v_cli_cnpj ||
                       ' não foi localizado na Empresa ' || v_nome_empresa;
         RAISE v_exception;
        END IF;
       
        -- Obter o pessoa_id se o cliente com o CNPJ existir
        SELECT MAX(pessoa_id)
          INTO v_cliente_id
          FROM pessoa pe
         WHERE (pe.cnpj = v_cli_cnpj OR pe.cpf = v_cli_cpf)
           AND empresa_id = v_empresa_id;
       END IF;
       --ALCBO_090125
       IF v_qtd_jobs_ganhar_oport = 'UM_POR_SERVICO'
       THEN
        SELECT cenario_servico_id,
               mes_ano_inicio,
               duracao_meses
          INTO v_cenario_servico_id,
               v_mes_ano_inicio,
               v_duracao_meses
          FROM cenario_servico
         WHERE cenario_id = p_cenario_escolhido_id
           AND servico_id = r_cs.servico_id
           AND descricao = r_cs.descricao;
        --
        SELECT c.contrato_servico_id
          INTO v_contrato_servico_id
          FROM contrato_servico c
         INNER JOIN cenario_servico s
            ON s.servico_id = c.servico_id
           AND s.descricao = c.descricao
         WHERE c.contrato_id = v_contrato_id
           AND s.cenario_servico_id = v_cenario_servico_id;
        --inserção dos gargos do cenário ganho no contrato
        INSERT INTO contrato_horas
         (contrato_horas_id,
          contrato_servico_id,
          contrato_id,
          usuario_id,
          area_id,
          cargo_id,
          nivel,
          descricao,
          horas_planej,
          custo_hora_pdr,
          venda_hora_pdr,
          venda_hora_rev,
          venda_fator_ajuste,
          data)
         SELECT seq_contrato_horas.nextval, --contrato_horas_id
                v_contrato_servico_id, --contrato_servico_id
                v_contrato_id, --contrato_id
                NULL, --usuario_id
                h.area_id, --area_id
                h.cargo_id, --cargo_id
                h.nivel, --nivel
                h.nome_alternativo, --descricaototais
                h.hora_mes, --horas_planej
                util_pkg.num_encode(h.custo_hora), --custo_hora_pdr
                /*ALCBO_300824
                antes
                --util_pkg.num_encode(round(h.preco_venda / h.horas_totais, 2)),
                --util_pkg.num_encode(round(h.preco_venda / h.horas_totais, 2)),
                */
                CASE
                 WHEN h.horas_totais <> 0 THEN
                  util_pkg.num_encode(round(h.preco_venda / h.horas_totais, 2))
                 ELSE
                  0
                END AS venda_hora_pdr, --venda_hora_pdr
                CASE
                 WHEN h.horas_totais <> 0 THEN
                  util_pkg.num_encode(round(h.preco_venda / h.horas_totais, 2))
                 ELSE
                  0
                END AS venda_hora_rev, --venda_hora_rev
                1,
                --venda_fator_ajuste
                data_inicio --data
           FROM cenario_servico_horas h
          INNER JOIN cenario_servico s
             ON s.cenario_servico_id = h.cenario_servico_id
          INNER JOIN cenario c
             ON c.cenario_id = s.cenario_id
          CROSS JOIN (SELECT DISTINCT add_months(v_mes_ano_inicio, LEVEL - 1) AS data_inicio
                        FROM dual
                      CONNECT BY LEVEL <= v_duracao_meses
                       ORDER BY 1 ASC)
          WHERE s.cenario_servico_id = v_cenario_servico_id;
        --
        --inserção dos itens do cenário ganho no contrato
        INSERT INTO contrato_item
         (contrato_item_id,
          contrato_servico_id,
          contrato_id,
          tipo_produto_id,
          fornecedor_id,
          complemento,
          custo_unitario,
          quantidade,
          unidade_freq,
          frequencia,
          mod_contr,
          custo_total,
          honorarios,
          taxas,
          honorario,
          taxa,
          preco_venda,
          preco_final)
         SELECT seq_contrato_item.nextval, --contrato_item_id
                v_contrato_servico_id, --contrato_servico_id
                v_contrato_id, --contrato_id
                i.tipo_produto_id,
                i.fornecedor_id,
                i.complemento,
                i.custo_unitario,
                i.quantidade,
                i.unidade_freq,
                i.frequencia,
                i.mod_contr,
                i.custo_total,
                i.honorarios,
                i.taxas,
                i.honorario,
                i.taxa,
                i.preco_venda,
                i.preco_final
           FROM cenario_servico_item i
          INNER JOIN cenario_servico s
             ON s.cenario_servico_id = i.cenario_servico_id
          INNER JOIN cenario c
             ON c.cenario_id = s.cenario_id
          WHERE s.cenario_servico_id = v_cenario_servico_id;
        --
        ---------------------------------------------------------------------
        --Adicionar Job
        ---------------------------------------------------------------------
        --
        /*--ALCBO_230424
        SELECT nome
          INTO v_nome_empresa
          FROM empresa
         WHERE empresa_id = v_empresa_id;
        --*/
        /*IF v_cli_flag_exterior = 'S' THEN
         SELECT COUNT(*)
           INTO v_qt
           FROM pessoa pe
          INNER JOIN tipific_pessoa tip
             ON tip.pessoa_id = pe.pessoa_id
          INNER JOIN tipo_pessoa tp
             ON tip.tipo_pessoa_id = tp.tipo_pessoa_id
          WHERE tp.codigo = 'ESTRANGEIRO'
            AND pe.empresa_id = v_empresa_id
            AND pe.nome = TRIM(v_cli_nome); --pega pelo apelido(sem cnpj/cpf)
        
         IF v_qt = 0 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'O cliente ' || v_cli_nome || ' não foi localizado na Empresa ' ||
                        v_nome_empresa;
          RAISE v_exception;
         END IF;
        
         -- Obter o pessoa_id se o cliente existir
         SELECT MAX(pessoa_id) --ALCBO_130624
           INTO v_cliente_id
           FROM pessoa pe
          WHERE pe.nome = TRIM(v_cli_nome)
            AND pe.empresa_id = v_empresa_id;
        ELSE
         -- v_cli_flag_exterior = N
         SELECT COUNT(*)
           INTO v_qt
           FROM pessoa pe
          WHERE (pe.cnpj = v_cli_cnpj OR pe.cpf = v_cli_cpf)
            AND pe.empresa_id = v_empresa_id;
         --
         IF v_qt = 0 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'O cliente ' || v_cli_nome || ' que possui o CNPJ ' || v_cli_cnpj ||
                        ' não foi localizado na Empresa ' || v_nome_empresa;
          RAISE v_exception;
         END IF;
        
         -- Obter o pessoa_id se o cliente com o CNPJ existir
         SELECT pessoa_id
           INTO v_cliente_id
           FROM pessoa pe
          WHERE (pe.cnpj = v_cli_cnpj OR pe.cpf = v_cli_cpf)
            AND empresa_id = v_empresa_id;
        END IF;*/
       
        -- Verificação adicional para CPF (se necessário)
        IF v_cli_cpf IS NOT NULL
        THEN
         SELECT COUNT(*)
           INTO v_qt
           FROM pessoa pe
          WHERE pe.cpf = v_cli_cpf
            AND pe.empresa_id = v_empresa_id;
        
         IF v_qt = 0
         THEN
          p_erro_cod := '90000';
          p_erro_msg := 'O cliente ' || v_cli_nome || ' que possui o CPF ' || v_cli_cpf ||
                        ' não foi localizado na Empresa ' || v_nome_empresa;
          RAISE v_exception;
         END IF;
         -- Obter o pessoa_id se o cliente com o CPF existir
         SELECT pessoa_id
           INTO v_cliente_id
           FROM pessoa
          WHERE cpf = v_cli_cpf
            AND empresa_id = v_empresa_id;
        END IF; --fim verificacao que existe o cliente
        --criar Job
        job_pkg.adicionar(p_usuario_sessao_id, --p_usuario_sessao_id
                          v_empresa_id, --p_empresa_i,d--ALCBO_100424
                          v_cliente_id, --p_cliente_id
                          v_emp_resp_id, --p_emp_resp_id
                          v_tipo_job_id, --p_tipo_job_id
                          v_tipo_financeiro_id, --p_tipo_financeiro_id
                          v_contrato_id, --p_contrato_id
                          NULL, --p_campanha_id
                          NULL, --p_numero_job
                          NULL, --p_cod_ext_job,
                          --ALCBO_190724
                          substr(v_nome_oport || ' - ' || r_cs.servico_nome, 1, 60), --p_nome
                          'Aberto automaticamente a partir da Oportunidade ganha ' ||
                          v_numero_oport || ' - ' || v_nome_oport, --p_descricao
                          'ND', --p_complex_job
                          'N', --flag_commit
                          v_produto_cliente_id, --ALCBO_110424
                          v_data_inicio, --ALCBO_110424
                          v_data_termino, --ALCBO_110424
                          v_job_id, --p_job_id
                          p_erro_cod, --p_erro_cod
                          p_erro_msg --p_erro_msg);
                          );
        --
        IF p_erro_cod <> '00000'
        THEN
         RAISE v_exception;
        END IF;
        --J_130624
        SELECT MAX(unu.unidade_negocio_id)
          INTO v_unidade_negocio_id
          FROM unidade_negocio_usu unu
         INNER JOIN contrato_usuario cu
            ON unu.usuario_id = cu.usuario_id
           AND cu.flag_responsavel = 'S'
           AND cu.contrato_id = v_contrato_id;
        --J_130624
        UPDATE job
           SET unidade_negocio_id = v_unidade_negocio_id
         WHERE job_id = v_job_id;
        --atualiza o serviço do Job
        UPDATE job
           SET servico_id = r_cs.servico_id
         WHERE job_id = v_job_id;
        --copia as horas vendidas da Oportunidade para horas planejadas do Job
        INSERT INTO job_horas
         (job_horas_id,
          job_id,
          usuario_id,
          area_id,
          cargo_id,
          nivel,
          horas_planej,
          custo_hora_pdr,
          venda_hora_pdr,
          venda_hora_rev,
          venda_fator_ajuste)
         SELECT seq_job_horas.nextval, --contrato_horas_id
                v_job_id, --contrato_id
                NULL, --usuario_id
                h.area_id, --area_id
                h.cargo_id, --cargo_id
                h.nivel, --nivel
                --h.nome_alternativo, --descricaototais
                h.horas_totais, --horas_planej
                util_pkg.num_encode(h.custo_hora), --custo_hora_pdr
                /*ALCBO_300824
                --util_pkg.num_encode(round(h.preco_final / h.horas_totais, 2)), --venda_hora_pdr
                util_pkg.num_encode(round(h.preco_final / h.horas_totais, 2)), --venda_hora_rev
                */
                CASE
                 WHEN h.horas_totais <> 0 THEN
                  util_pkg.num_encode(round(h.preco_final / h.horas_totais, 2))
                 ELSE
                  0
                END AS venda_hora_pdr, --venda_hora_pdr
                CASE
                 WHEN h.horas_totais <> 0 THEN
                  util_pkg.num_encode(round(h.preco_final / h.horas_totais, 2))
                 ELSE
                  0
                END AS venda_hora_rev, --venda_hora_rev
                1
           FROM cenario_servico_horas h
          INNER JOIN cenario_servico s
             ON s.cenario_servico_id = h.cenario_servico_id
          WHERE s.cenario_servico_id = v_cenario_servico_id
            AND s.servico_id = r_cs.servico_id;
        --
        --END IF; --fim verificacao que existe o cliente
        --ALCBO_090125
       ELSE
        --parametro = UM 
       
        --PARAMETRO v_qtd_jobs_ganhar_oport ='UM'
        -- Criar um job por contrato
        -- Variável para controlar se um job já foi criado para o contrato atual
        v_job_ja_criado := 'N';
        IF v_job_ja_criado = 'N'
        THEN
         /*IF 1 = 1 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'p_usuario_sessao_id: ' || p_usuario_sessao_id || ', p_empresa_id: ' ||
                        v_empresa_id || ', p_cliente_id: ' || v_cliente_id || ', p_emp_resp_id: ' ||
                        v_emp_resp_id || ', p_tipo_job_id: ' || v_tipo_job_id ||
                        ', p_tipo_financeiro_id: ' || v_tipo_financeiro_id || ', p_contrato_id: ' ||
                        v_contrato_id || ', p_campanha_id: ' || NULL || ', p_numero_job: ' || NULL ||
                        ', p_cod_ext_job: ' || NULL || ', p_nome: ' ||
                        substr(v_nome_oport || ' - ' || r_cs.servico_nome, 1, 60) ||
                        ', p_descricao: ' ||
                        'Aberto automaticamente a partir da Oportunidade ganha ' || v_numero_oport ||
                        ' - ' || v_nome_oport || ', p_complex_job: ' || 'ND' || ', flag_commit: ' || 'N' ||
                        ', v_produto_cliente_id: ' || v_produto_cliente_id || ', v_data_inicio: ' ||
                        v_data_inicio || ', v_data_termino: ' || v_data_termino || ', v_job_id: ' ||
                        v_job_id;
          RAISE v_exception;
         END IF;*/
         -- Criar o primeiro job para este contrato
         job_pkg.adicionar(p_usuario_sessao_id, --p_usuario_sessao_id
                           v_empresa_id, --p_empresa_id--ALCBO_100424
                           v_cliente_id, --p_cliente_id
                           v_emp_resp_id, --p_emp_resp_id
                           v_tipo_job_id, --p_tipo_job_id
                           v_tipo_financeiro_id, --p_tipo_financeiro_id
                           v_contrato_id, --p_contrato_id
                           NULL, --p_campanha_id
                           NULL, --p_numero_job
                           NULL, --p_cod_ext_job
                           substr(v_nome_oport || ' - ' || r_cs.servico_nome, 1, 60), --p_nome
                           'Aberto automaticamente a partir da Oportunidade ganha ' ||
                           v_numero_oport || ' - ' || v_nome_oport, --p_descricao
                           'ND', --p_complex_job
                           'N', --flag_commit
                           v_produto_cliente_id, --ALCBO_110424
                           v_data_inicio, --ALCBO_110424
                           v_data_termino, --ALCBO_110424
                           v_job_id, --p_job_id
                           p_erro_cod, --p_erro_cod
                           p_erro_msg --p_erro_msg
                           );
         --
         IF p_erro_cod <> '00000'
         THEN
          RAISE v_exception;
         END IF;
         --
         v_job_ja_criado := 'S';
         EXIT; -- Sai do loop após criar o primeiro job
        END IF; --IF SE JOB JA CRIADO
       END IF; --IF PARAMETRO 
      END LOOP; --Fim loop servico
     END IF; --FIM CURSOR OPORT_SERVICO
    ELSE
     -- contrato ja existe. Atualiza a data_entrada.
     UPDATE contrato
        SET data_entrada    = SYSDATE,
            flag_renovavel  = v_flag_renovavel,
            flag_ctr_fisico = v_flag_ctr_fisico
      WHERE contrato_id = v_contrato_id;
    END IF;
    --
    UPDATE cenario_empresa
       SET data_inicio_ctr  = v_data_inicio,
           data_termino_ctr = v_data_termino,
           flag_renovavel   = v_flag_renovavel,
           flag_ctr_fisico  = v_flag_ctr_fisico,
           emp_resp_ctr_id  = zvl(v_emp_resp_id, NULL)
     WHERE cenario_empresa_id = v_cenario_empresa_id;
   END LOOP; --FIM LOOP v_vetor_ctr_empresa_id
  END IF; --IF PARA CRIAR CONTRATO
  --
  ------------------------------------------------------------
  -- muda o status da oportunidade
  ------------------------------------------------------------
  oportunidade_pkg.status_alterar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_oportunidade_id,
                                  'CONC',
                                  0,
                                  v_tipo_conc,
                                  NULL,
                                  NULL,
                                  NULL,
                                  'N',
                                  p_erro_cod,
                                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END interacao_ganha_adicionar;
 --
 --
 PROCEDURE interacao_perda_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/07/2019
  -- DESCRICAO: Nova interacao com mudanca de status para conclusão com perda
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_int1_data         IN VARCHAR2,
  p_int1_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato IN VARCHAR2,
  p_int1_descricao    IN interacao.descricao%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_perda_para        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_tipo_conc           oportunidade.tipo_conc%TYPE;
  v_numero_oport        oportunidade.numero%TYPE;
  v_status_oport        oportunidade.status%TYPE;
  v_status_aux_oport_id oportunidade.status_aux_oport_id%TYPE;
  v_data_interacao1     interacao.data_interacao%TYPE;
  v_interacao_id        interacao.interacao_id%TYPE;
  v_apelido             pessoa.apelido%TYPE;
  --
 BEGIN
  v_qt        := 0;
  v_tipo_conc := 'PER';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CONC',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status,
         op.status_aux_oport_id
    INTO v_numero_oport,
         v_status_oport,
         v_status_aux_oport_id
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_int1_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da Interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int1_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da Interação inválida (' || p_int1_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao1 := data_converter(p_int1_data);
  --
  IF nvl(p_int1_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Autor/Responsável pela interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Meio de Contato da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_meio_contato', p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Meio de Contato inválido (' || p_int1_meio_contato || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_int1_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição/Resumo da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_interacao.nextval
    INTO v_interacao_id
    FROM dual;
  --
  INSERT INTO interacao
   (interacao_id,
    oportunidade_id,
    usuario_resp_id,
    data_entrada,
    data_interacao,
    descricao,
    meio_contato,
    perc_prob_fech,
    data_prov_fech,
    usuario_prox_int_id,
    data_prox_int,
    desc_prox_int,
    status_aux_oport_id)
  VALUES
   (v_interacao_id,
    p_oportunidade_id,
    p_int1_usuario_id,
    SYSDATE,
    v_data_interacao1,
    p_int1_descricao,
    p_int1_meio_contato,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    v_status_aux_oport_id);
  --
  oportunidade_pkg.status_alterar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_oportunidade_id,
                                  'CONC',
                                  0,
                                  v_tipo_conc,
                                  p_motivo,
                                  p_complemento,
                                  p_perda_para,
                                  'N',
                                  p_erro_cod,
                                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do autor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_int1_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int1_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      p_oportunidade_id,
                                      p_int1_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Oportunidade Perdida',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END interacao_perda_adicionar;
 --
 --
 PROCEDURE interacao_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Atualizacao de INTERACAO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/06/2021  Deixa repetir data da interacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_interacao_id      IN interacao.interacao_id%TYPE,
  p_int1_data         IN VARCHAR2,
  p_int1_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato IN VARCHAR2,
  p_int1_descricao    IN interacao.descricao%TYPE,
  p_perc_prob_fech    IN VARCHAR2,
  p_data_prov_fech    IN VARCHAR2,
  p_int2_data         IN VARCHAR2,
  p_int2_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao    IN interacao.descricao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  v_data_interacao  interacao.data_interacao%TYPE;
  v_interacao_id    interacao.interacao_id%TYPE;
  v_perc_prob_fech  interacao.perc_prob_fech%TYPE;
  v_data_prov_fech  interacao.data_prov_fech%TYPE;
  v_data_prox_int   interacao.data_prox_int%TYPE;
  v_data_interacao1 interacao.data_interacao%TYPE;
  v_data_interacao2 interacao.data_interacao%TYPE;
  v_apelido         pessoa.apelido%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM interacao
   WHERE interacao_id = p_interacao_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Interação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM interacao
   WHERE interacao_id = p_interacao_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = v_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_int1_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da Interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int1_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da Interação inválida (' || p_int1_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao1 := data_converter(p_int1_data);
  --
  IF nvl(p_int1_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Autor/Responsável pela interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Meio de Contato da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('oportunidade_meio_contato', p_int1_meio_contato) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Meio de Contato inválido (' || p_int1_meio_contato || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_int1_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição/Resumo da interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_perc_prob_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Probabilidade de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_prob_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual da Probabilidade de Fechamento inválido (' || p_perc_prob_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_prob_fech := nvl(taxa_converter(p_perc_prob_fech), 0);
  --
  IF TRIM(p_data_prov_fech) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data Provável de Fechamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prov_fech) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data Provável de Fechamento inválida (' || p_data_prov_fech || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prov_fech := data_converter(p_data_prov_fech);
  --
  IF TRIM(p_int2_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Data da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_int2_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da próxima interação inválida (' || p_int2_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interacao2 := data_converter(p_int2_data);
  --
  IF nvl(p_int2_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pela próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_int2_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Descrição da próxima interação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM interacao
     WHERE oportunidade_id = v_oportunidade_id
       AND data_interacao = v_data_interacao1
       AND interacao_id <> p_interacao_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Já existe uma interação registrada nessa data ('||
                     data_mostrar(v_data_interacao1) || ').';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE interacao
     SET usuario_resp_id     = p_int1_usuario_id,
         data_interacao      = v_data_interacao1,
         descricao           = TRIM(p_int1_descricao),
         meio_contato        = p_int1_meio_contato,
         perc_prob_fech      = v_perc_prob_fech,
         data_prov_fech      = v_data_prov_fech,
         usuario_prox_int_id = p_int2_usuario_id,
         data_prox_int       = v_data_interacao2,
         desc_prox_int       = TRIM(p_int2_descricao)
   WHERE interacao_id = p_interacao_id;
  --
  -- procura a interacao atual
  SELECT MAX(data_interacao)
    INTO v_data_interacao
    FROM interacao
   WHERE oportunidade_id = v_oportunidade_id;
  --
  IF v_data_interacao IS NOT NULL
  THEN
   SELECT MAX(interacao_id)
     INTO v_interacao_id
     FROM interacao
    WHERE oportunidade_id = v_oportunidade_id
      AND data_interacao = v_data_interacao;
   --
   SELECT perc_prob_fech,
          data_prov_fech,
          data_prox_int
     INTO v_perc_prob_fech,
          v_data_prov_fech,
          v_data_prox_int
     FROM interacao
    WHERE interacao_id = v_interacao_id;
   --
   UPDATE oportunidade
      SET perc_prob_fech = v_perc_prob_fech,
          data_prov_fech = v_data_prov_fech,
          data_prox_int  = v_data_prox_int
    WHERE oportunidade_id = v_oportunidade_id;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do autor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = v_oportunidade_id
     AND usuario_id = p_int1_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int1_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      v_oportunidade_id,
                                      p_int1_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Alteração de Follow-up',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do responsavel pela proxima
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = v_oportunidade_id
     AND usuario_id = p_int2_usuario_id;
  --
  IF v_qt = 0
  THEN
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_int2_usuario_id;
   --
   -- a subrotina marca como: com co-ender, sem pula notif
   oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                      'N',
                                      'S',
                                      'N',
                                      p_empresa_id,
                                      v_oportunidade_id,
                                      p_int2_usuario_id,
                                      v_apelido || ' endereçado automaticamente',
                                      'Alteração de Follow-up',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport;
  v_compl_histor   := 'Alteração de Interação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END interacao_atualizar;
 --
 --
 PROCEDURE interacao_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Exclusao de INTERACAO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_interacao_id      IN interacao.interacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  v_data_interacao  interacao.data_interacao%TYPE;
  v_interacao_id    interacao.interacao_id%TYPE;
  v_perc_prob_fech  interacao.perc_prob_fech%TYPE;
  v_data_prov_fech  interacao.data_prov_fech%TYPE;
  v_data_prox_int   interacao.data_prox_int%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM interacao
   WHERE interacao_id = p_interacao_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Interação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM interacao
   WHERE interacao_id = p_interacao_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = v_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM interacao
   WHERE interacao_id = p_interacao_id;
  --
  -- procura a interacao anterior
  SELECT MAX(data_interacao)
    INTO v_data_interacao
    FROM interacao
   WHERE oportunidade_id = v_oportunidade_id;
  --
  IF v_data_interacao IS NOT NULL
  THEN
   SELECT MAX(interacao_id)
     INTO v_interacao_id
     FROM interacao
    WHERE oportunidade_id = v_oportunidade_id
      AND data_interacao = v_data_interacao;
   --
   SELECT perc_prob_fech,
          data_prov_fech,
          data_prox_int
     INTO v_perc_prob_fech,
          v_data_prov_fech,
          v_data_prox_int
     FROM interacao
    WHERE interacao_id = v_interacao_id;
   --
   UPDATE oportunidade
      SET perc_prob_fech = v_perc_prob_fech,
          data_prov_fech = v_data_prov_fech,
          data_prox_int  = v_data_prox_int
    WHERE oportunidade_id = v_oportunidade_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport;
  v_compl_histor   := 'Exclusão de Interação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END interacao_excluir;
 --
 --
 PROCEDURE status_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Alteracao do status de uma determinada OPORTUNIDADE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/01/2021  Deleta oport_servico na reabertura
  -- Silvia            17/12/2021  Exclusao de vinculo c/ contrato na reabertura comentada.
  -- Ana Luiza         11/12/2023  Adicionado arquivo_acei_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id     IN oportunidade.oportunidade_id%TYPE,
  p_status              IN oportunidade.status%TYPE,
  p_status_aux_oport_id IN status_aux_oport.status_aux_oport_id%TYPE,
  p_tipo_conc           IN VARCHAR2,
  p_motivo              IN VARCHAR2,
  p_complemento         IN VARCHAR2,
  p_perda_para          IN VARCHAR2,
  p_flag_commit         IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_numero_oport            oportunidade.numero%TYPE;
  v_status_oport_old        oportunidade.status%TYPE;
  v_desc_status_old         VARCHAR(100);
  v_desc_status             VARCHAR(100);
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_cod_acao                tipo_acao.codigo%TYPE;
  v_status_aux_oport_id     status_aux_oport.status_aux_oport_id%TYPE;
  v_status_aux_oport_id_old status_aux_oport.status_aux_oport_id%TYPE;
  v_nome_status_aux         status_aux_oport.nome%TYPE;
  v_interacao_id            interacao.interacao_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status,
         util_pkg.desc_retornar('status_oportunidade', op.status),
         op.status_aux_oport_id
    INTO v_numero_oport,
         v_status_oport_old,
         v_desc_status_old,
         v_status_aux_oport_id_old
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id
     AND op.empresa_id = p_empresa_id;
  --
  IF p_status = 'ANDA' AND v_status_oport_old IN ('CONC', 'CANC')
  THEN
   v_cod_acao := 'REABRIR';
  ELSIF p_status = 'CONC' AND p_tipo_conc = 'GAN'
  THEN
   v_cod_acao := 'CONCLUIR';
  ELSIF p_status = 'CONC' AND p_tipo_conc = 'PER'
  THEN
   v_cod_acao := 'CONCLUIR_PERDA';
  ELSIF p_status = 'CANC'
  THEN
   v_cod_acao := 'CANCELAR';
  ELSE
   -- transicao nao prevista. Registra como alteracao.
   v_cod_acao := 'ALTERAR';
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_status) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(descricao)
    INTO v_desc_status
    FROM dicionario
   WHERE tipo = 'status_oportunidade'
     AND codigo = p_status;
  --
  IF v_desc_status IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do status inválido (' || p_status || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   -- chamada direta da interface
   IF p_status = 'CONC'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'OPORTUN_CONC',
                                  p_oportunidade_id,
                                  NULL,
                                  p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSIF p_status = 'CANC'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'OPORTUN_CANC',
                                  p_oportunidade_id,
                                  NULL,
                                  p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSIF p_status = 'ANDA' AND v_status_oport_old IN ('CONC', 'CANC')
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPORTUN_REAB', NULL, NULL, p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSE
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'OPORTUN_A',
                                  p_oportunidade_id,
                                  NULL,
                                  p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF; -- fim do IF p_flag_commit = 'S'
  --
  IF p_status = 'CONC' AND v_status_oport_old = 'CANC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Oportunidade "Cancelada" não pode ser concluída.';
   RAISE v_exception;
  END IF;
  --
  IF p_status = 'CANC' AND v_status_oport_old = 'CONC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Oportunidade "Concluída" não pode ser cancelada.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_status_aux_oport_id, 0) > 0
  THEN
   -- usa o status estendido passado pela interface
   v_status_aux_oport_id := p_status_aux_oport_id;
  ELSE
   -- descobre o status estendido padrao
   SELECT MAX(status_aux_oport_id)
     INTO v_status_aux_oport_id
     FROM status_aux_oport
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = p_status
      AND flag_padrao = 'S';
   --
   IF v_status_aux_oport_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Status estendido padrão não encontrado para essa transição.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- verifica se eh compativel
  SELECT MAX(nome)
    INTO v_nome_status_aux
    FROM status_aux_oport
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = p_status
     AND flag_ativo = 'S'
     AND status_aux_oport_id = v_status_aux_oport_id;
  --
  IF v_nome_status_aux IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido inválido para essa transição.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_aux_oport_id = v_status_aux_oport_id_old
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade já se encontra nesse status.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_perda_para)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Perdemos Para não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF (p_status = 'CONC' AND p_tipo_conc = 'PER') OR p_status = 'CANC'
  THEN
   IF TRIM(p_motivo) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do motivo é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oportunidade
     SET status              = p_status,
         tipo_conc           = TRIM(p_tipo_conc),
         data_status         = trunc(SYSDATE),
         status_aux_oport_id = v_status_aux_oport_id,
         motivo_status       = TRIM(p_motivo),
         compl_status        = TRIM(p_complemento)
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_cod_acao = 'REABRIR'
  THEN
   SELECT MAX(interacao_id)
     INTO v_interacao_id
     FROM interacao
    WHERE oportunidade_id = p_oportunidade_id;
   --
   UPDATE oportunidade
      SET tipo_conc            = NULL,
          perda_para           = NULL,
          arquivo_prop_id      = NULL,
          arquivo_prec_id      = NULL,
          arquivo_acei_id      = NULL, --ALCBO_141223
          cenario_escolhido_id = NULL,
          motivo_status        = NULL,
          compl_status         = NULL
    WHERE oportunidade_id = p_oportunidade_id;
   --
   UPDATE interacao
      SET status_aux_oport_id = v_status_aux_oport_id
    WHERE interacao_id = v_interacao_id;
   --
   DELETE FROM oport_servico
    WHERE oportunidade_id = p_oportunidade_id;
   --
   /*
   DELETE FROM oport_contrato
    WHERE oportunidade_id = p_oportunidade_id;
   */
  END IF;
  --
  IF v_cod_acao = 'CONCLUIR_PERDA'
  THEN
   UPDATE oportunidade
      SET perda_para = TRIM(p_perda_para)
    WHERE oportunidade_id = p_oportunidade_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  IF p_status = 'CANC'
  THEN
   v_compl_histor := 'Status: ' || v_desc_status;
  ELSIF p_status = 'CONC'
  THEN
   IF p_tipo_conc = 'GAN'
   THEN
    v_compl_histor := 'Status: ' || v_desc_status || ' - ' || 'Ganha';
   ELSE
    v_compl_histor := 'Status: ' || v_desc_status || ' - ' || 'Perdida';
   END IF;
  ELSE
   v_compl_histor := 'Status: ' || v_desc_status || ' - ' || v_nome_status_aux;
  END IF;
  --
  IF TRIM(p_complemento) IS NOT NULL
  THEN
   v_compl_histor := substr(v_compl_histor || ' (' || p_complemento || ')', 1, 1000);
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   v_cod_acao,
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   p_motivo,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('OPORTUNIDADE_JOB_STATUS_ATUALIZAR',
                           p_empresa_id,
                           p_oportunidade_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END status_alterar;
 --
 --
 PROCEDURE desenderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: subrotina que desendereca um determinado usuario da oportunidade.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_numero_oport   oportunidade.numero%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pula_notif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pula notif inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe (' || to_char(p_oportunidade_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT numero
    INTO v_numero_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt > 0
  THEN
   DELETE FROM oport_usuario
    WHERE oportunidade_id = p_oportunidade_id
      AND usuario_id = p_usuario_id;
   --
   v_identif_objeto := to_char(v_numero_oport);
   v_compl_histor   := TRIM(p_complemento);
   v_justif_histor  := TRIM(p_justificativa);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'OPORTUNIDADE',
                    'DESENDERECAR',
                    v_identif_objeto,
                    p_oportunidade_id,
                    v_compl_histor,
                    v_justif_histor,
                    p_flag_pula_notif,
                    NULL,
                    NULL,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   INSERT INTO notifica_usu_avulso
    (historico_id,
     usuario_id,
     papel_id,
     tipo_notifica)
   VALUES
    (v_historico_id,
     p_usuario_id,
     NULL,
     'PADRAO');
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END desenderecar_usuario;
 --
 --
 PROCEDURE enderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: subrotina que endereca um determinado usuario na oportunidade, caso ele
  --   ainda nao esteja enderecado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Silvia            16/09/2020  Tratar responsavel interno
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_coender      IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_numero_oport   oportunidade.numero%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_coender) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag coender inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pula_notif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pula notif inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe (' || to_char(p_oportunidade_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT numero
    INTO v_numero_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se o usuario ja esta enderecado
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0
  THEN
   -- usuario ainda nao esta enderecado
   INSERT INTO oport_usuario
    (oportunidade_id,
     usuario_id)
   VALUES
    (p_oportunidade_id,
     p_usuario_id);
   --
   historico_pkg.hist_ender_registrar(p_usuario_id,
                                      'OPO',
                                      p_oportunidade_id,
                                      NULL,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- verifica se esse usuario pode ser resp interno e marca
   resp_int_tratar(p_oportunidade_id, p_usuario_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- geracao de evento
   v_identif_objeto := v_numero_oport;
   v_compl_histor   := TRIM(p_complemento);
   v_justif_histor  := TRIM(p_justificativa);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'OPORTUNIDADE',
                    'ENDERECAR',
                    v_identif_objeto,
                    p_oportunidade_id,
                    v_compl_histor,
                    v_justif_histor,
                    p_flag_pula_notif,
                    NULL,
                    NULL,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   INSERT INTO notifica_usu_avulso
    (historico_id,
     usuario_id,
     papel_id,
     tipo_notifica)
   VALUES
    (v_historico_id,
     p_usuario_id,
     NULL,
     'PADRAO');
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END enderecar_usuario;
 --
 --
 PROCEDURE enderecar_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: subrotina p/ Enderecamento automatico do OPORTUNIDADE.
  --            NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Silvia            16/09/2020  Tratar responsavel interno
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_numero_oport   oportunidade.numero%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  CURSOR c_usu IS
  -- usuario com papel de criador
   SELECT 1 AS ordem,
          up.usuario_id,
          pa.papel_id,
          pa.nome AS nome_papel,
          pe.apelido AS nome_usuario,
          'CRIADOR' AS tipo_ender
     FROM usuario_papel up,
          papel         pa,
          pessoa        pe,
          papel_priv    pp2,
          privilegio    pr2
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.flag_ender = 'S'
      AND up.usuario_id = pe.usuario_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp2.papel_id
      AND pp2.privilegio_id = pr2.privilegio_id
      AND pr2.codigo = 'OPORTUN_I'
      AND rownum = 1
   UNION
   -- usuarios com papeis autoenderecaveis
   SELECT 2 AS ordem,
          up.usuario_id,
          pa.papel_id,
          pa.nome AS nome_papel,
          pe.apelido AS nome_usuario,
          'PAPEL_AUTO' AS tipo_ender
     FROM papel         pa,
          usuario_papel up,
          usuario       us,
          pessoa        pe
    WHERE pa.flag_auto_ender_oport = 'S'
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = up.papel_id
      AND up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
    ORDER BY 1;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT op.numero
    INTO v_numero_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- endereca automaticamente usuarios ativos c/ papel auto-enderecavel
  -- mais o criador
  FOR r_usu IN c_usu
  LOOP
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_usuario
    WHERE oportunidade_id = p_oportunidade_id
      AND usuario_id = r_usu.usuario_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO oport_usuario
     (oportunidade_id,
      usuario_id)
    VALUES
     (p_oportunidade_id,
      r_usu.usuario_id);
    --
    historico_pkg.hist_ender_registrar(r_usu.usuario_id,
                                       'OPO',
                                       p_oportunidade_id,
                                       NULL,
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- verifica se esse usuario pode ser resp interno e marca
    resp_int_tratar(p_oportunidade_id, r_usu.usuario_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- geracao de evento (sem pular notif)
    v_identif_objeto := v_numero_oport;
    v_compl_histor   := NULL;
    --
    IF r_usu.tipo_ender = 'CRIADOR'
    THEN
     v_compl_histor := r_usu.nome_usuario || '/' || r_usu.nome_papel || ' criou a Oportunidade';
    ELSIF r_usu.tipo_ender = 'PAPEL_AUTO'
    THEN
     v_compl_histor := r_usu.nome_usuario || '/' || r_usu.nome_papel ||
                       ' endereçado automaticamente em função do Papel';
    END IF;
    --
    v_justif_histor := 'Criação de Oportunidade';
    --
    evento_pkg.gerar(p_usuario_sessao_id,
                     p_empresa_id,
                     'OPORTUNIDADE',
                     'ENDERECAR',
                     v_identif_objeto,
                     p_oportunidade_id,
                     v_compl_histor,
                     v_justif_histor,
                     'N',
                     NULL,
                     NULL,
                     v_historico_id,
                     p_erro_cod,
                     p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    INSERT INTO notifica_usu_avulso
     (historico_id,
      usuario_id,
      papel_id,
      tipo_notifica)
    VALUES
     (v_historico_id,
      r_usu.usuario_id,
      r_usu.papel_id,
      'PADRAO');
   END IF;
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END enderecar_automatico;
 --
 --
 PROCEDURE enderecar_manual
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Enderecamento de usuarios da OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Ana Luiza         31/10/2023  Alteracao do privilegio e adicao area_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  v_vetor_usuarios VARCHAR2(500);
  v_delimitador    CHAR(1);
  v_usuario_id     usuario.usuario_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_apelido        pessoa.apelido%TYPE;
  --
  CURSOR c_us IS
   SELECT usuario_id
     FROM oport_usuario ou
    WHERE ou.oportunidade_id = p_oportunidade_id
      AND controle = 'DEL';
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_oport IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  -- ALCBO_311023
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_ENDER_AREA',
                                p_oportunidade_id,
                                p_area_id,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport NOT IN ('ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A área não foi informada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- marca os enderecamentos atuais como candidatos a serem deletados
  -- (apenas da area).
  UPDATE oport_usuario ou
     SET controle = 'DEL'
   WHERE ou.oportunidade_id = p_oportunidade_id
     AND EXISTS (SELECT 1
            FROM usuario us
           WHERE us.area_id = p_area_id
             AND us.usuario_id = ou.usuario_id);
  --
  v_delimitador    := ',';
  v_vetor_usuarios := rtrim(p_vetor_usuarios);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id
      AND area_id = p_area_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) ||
                  ' ou não pertence a essa área (area_id = ' || to_char(p_area_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_usuario
    WHERE oportunidade_id = p_oportunidade_id
      AND usuario_id = v_usuario_id;
   --
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    -- a subrotina marca como: com co-ender, sem pula notif
    oportunidade_pkg.enderecar_usuario(p_usuario_sessao_id,
                                       'N',
                                       'S',
                                       'N',
                                       p_empresa_id,
                                       p_oportunidade_id,
                                       v_usuario_id,
                                       v_apelido || ' endereçado manualmente',
                                       'Endereçamento Manual',
                                       p_erro_cod,
                                       p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- usuario JA enderecado.
    -- desmarca o controle de delecao
    UPDATE oport_usuario
       SET controle = NULL
     WHERE oportunidade_id = p_oportunidade_id
       AND usuario_id = v_usuario_id;
   END IF;
  END LOOP;
  --
  --
  -- desendereca usuarios que nao vieram no vetor
  FOR r_us IN c_us
  LOOP
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = r_us.usuario_id;
   --
   -- desendereca o usuario, sem pula notif
   oportunidade_pkg.desenderecar_usuario(p_usuario_sessao_id,
                                         'N',
                                         'N',
                                         p_empresa_id,
                                         p_oportunidade_id,
                                         r_us.usuario_id,
                                         v_apelido || ' desendereçado manualmente',
                                         'Desendereçamento Manual',
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END enderecar_manual;
 --
 --
 PROCEDURE cancelar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Cancelamento de OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_numero_oport oportunidade.numero%TYPE;
  v_status_oport oportunidade.status%TYPE;
  v_exception    EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CANC',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport NOT IN ('ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  oportunidade_pkg.status_alterar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_oportunidade_id,
                                  'CANC',
                                  0,
                                  NULL,
                                  p_motivo,
                                  p_complemento,
                                  NULL,
                                  'N',
                                  p_erro_cod,
                                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END cancelar;
 --
 --
 PROCEDURE reabrir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Reabertura de OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/12/2021  Codigo de cancelamento de contrato comentado.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_numero_oport oportunidade.numero%TYPE;
  v_status_oport oportunidade.status%TYPE;
  v_exception    EXCEPTION;
  v_lbl_jobs     VARCHAR2(100);
  v_complemento  VARCHAR2(500);
  --
  CURSOR c_ct IS
   SELECT contrato_id
     FROM oport_contrato
    WHERE oportunidade_id = p_oportunidade_id;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_REAB',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport NOT IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  /*
    -- verificacao de jobs associados a contratos
    SELECT COUNT(*)
      INTO v_qt
      FROM oport_contrato oc
     WHERE oc.oportunidade_id = p_oportunidade_id
       AND EXISTS (SELECT 1
                     FROM job jo
                    WHERE jo.contrato_id = oc.contrato_id);
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Não é possível reabrir esta Oportunidade pois existem ' ||
                     v_lbl_jobs || ' já associados.';
       RAISE v_exception;
    END IF;
  --
    -- verificacao de contratos com faturamento comandado
    SELECT COUNT(*)
      INTO v_qt
      FROM oport_contrato oc
     WHERE oc.oportunidade_id = p_oportunidade_id
       AND EXISTS (SELECT 1
                     FROM faturamento_ctr fa
                    WHERE fa.contrato_id = oc.contrato_id);
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Não é possível reabrir esta Oportunidade pois existem Contratos ' ||
                     'associados a ela que possuem faturamentos já comandados.';
       RAISE v_exception;
    END IF;
  --
    -- verificacao de contratos integrados a sistema externo
    SELECT COUNT(*)
      INTO v_qt
      FROM oport_contrato oc
     WHERE oc.oportunidade_id = p_oportunidade_id
       AND EXISTS (SELECT 1
                     FROM contrato_servico cs
                    WHERE oc.contrato_id = cs.contrato_id
                      AND cs.cod_ext_ctrser IS NOT NULL);
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Não é possível reabrir esta Oportunidade pois existem Contratos ' ||
                     'associados a ela que possuem integrações realizadas com sistemas externos.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco: cancelamento dos contratos
  ------------------------------------------------------------
  /*
    v_complemento := 'porque a Oportunidade ' || v_numero_oport || ' foi reaberta';
    FOR r_ct IN c_ct LOOP
        contrato_pkg.status_alterar(p_usuario_sessao_id, p_empresa_id, 'N',
                                    r_ct.contrato_id, 'CANC', v_complemento,
                                    p_erro_cod,p_erro_msg);
        --
        IF p_erro_cod <> '00000' THEN
           RAISE v_exception;
        END IF;
    END LOOP;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco: oportunidade
  ------------------------------------------------------------
  oportunidade_pkg.status_alterar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_oportunidade_id,
                                  'ANDA',
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  'N',
                                  p_erro_cod,
                                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END reabrir;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Exclusão de OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/01/2021  Nova tabela oport_servico
  -- Silvia            14/09/2022  Nova tabela apontam_oport
  -- Ana Luiza         01/11/2023  Adicionado novas condicoes para filhos de cenario_servico
  -- Ana Luiza         13/12/2023  Exclusao tab oport_potencial
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  v_data_entrada   oportunidade.data_entrada%TYPE;
  v_exception      EXCEPTION;
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
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         data_entrada
    INTO v_numero_oport,
         v_status_oport,
         v_data_entrada
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_E',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport NOT IN ('ANDA', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite a exclusão.';
   RAISE v_exception;
  END IF;
  --
  IF SYSDATE > v_data_entrada + 0.25 / 24
  THEN
   -- exclusao nao permitida depois de 15 min da criacao
   p_erro_cod := '90000';
   p_erro_msg := 'A exclusão da Oportunidade não é mais permitida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_cenario ac,
         cenario         ce
   WHERE ce.oportunidade_id = p_oportunidade_id
     AND ce.cenario_id = ac.cenario_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos de cenários associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cenários associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM interacao
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem registros de follow-up associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE oportunidade_id = p_oportunidade_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de hora associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_oport
   WHERE oportunidade_id = p_oportunidade_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de hora associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_potencial
   WHERE oportunidade_id = p_oportunidade_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem potenciais de geração de negócios associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --ALCBO_011123
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_usu
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem usuários endereçados na precificação associados a essa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_horas
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem horas associados na precificação dessa oportunidade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_item
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem itens associados na precificação dessa oportunidade.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oportunidade
     SET cenario_escolhido_id = NULL
   WHERE oportunidade_id = p_oportunidade_id;
  --
  DELETE FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oport_contrato
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oport_servico
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM cenario_servico cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  DELETE FROM cenario_empresa cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  --ALCBO_011123
  --Nao faz sentido manter modalidade de contratacao em um cenario que sera apagado.
  DELETE FROM cenario_mod_contr
   WHERE cenario_id IN (SELECT cenario_id
                          FROM cenario
                         WHERE oportunidade_id = p_oportunidade_id);
  DELETE FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM interacao
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: apaga completamente uma determinada OPORTUNIDADE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/09/2022  Tratamento de apontam_oport
  -- Ana Luiza         31/10/2023  Apagando novos objetos filhos de cenario_servico
  -- Ana Luiza         11/12/2023  Adicionado arquivo_acei_id
  -- Ana Luiza         13/12/2023  Exclusao tab oport_potencial
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
  CURSOR c_arq_op IS
   SELECT DISTINCT arquivo_id
     FROM arquivo_oportunidade
    WHERE oportunidade_id = p_oportunidade_id;
  --
  CURSOR c_arq_ce IS
   SELECT DISTINCT ac.arquivo_id
     FROM arquivo_cenario ac,
          cenario         ce
    WHERE ce.oportunidade_id = p_oportunidade_id
      AND ce.cenario_id = ac.cenario_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_X',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oportunidade
     SET arquivo_prop_id      = NULL,
         arquivo_prec_id      = NULL,
         arquivo_acei_id      = NULL, --ALCBO_141123
         cenario_escolhido_id = NULL
   WHERE oportunidade_id = p_oportunidade_id;
  --
  FOR r_arq_op IN c_arq_op
  LOOP
   DELETE FROM arquivo_oportunidade
    WHERE arquivo_id = r_arq_op.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_op.arquivo_id;
  END LOOP;
  --
  FOR r_arq_ce IN c_arq_ce
  LOOP
   DELETE FROM arquivo_cenario
    WHERE arquivo_id = r_arq_ce.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ce.arquivo_id;
  END LOOP;
  --
  DELETE FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oport_contrato
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oport_servico
   WHERE oportunidade_id = p_oportunidade_id;
  --ALCBO_131223
  DELETE FROM oport_potencial
   WHERE oportunidade_id = p_oportunidade_id;
  --ALCBO_311023
  DELETE FROM cenario_servico_usu
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
  DELETE FROM cenario_servico_item
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
 
  DELETE FROM cenario_servico_horas
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE oportunidade_id = p_oportunidade_id));
  DELETE FROM cenario_mod_contr
   WHERE cenario_id IN (SELECT cenario_id
                          FROM cenario
                         WHERE oportunidade_id = p_oportunidade_id);
  --
  DELETE FROM cenario_servico cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  DELETE FROM cenario_empresa cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  DELETE FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM interacao
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM apontam_oport
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM apontam_hora
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'APAGAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END apagar;
 --
 --
 PROCEDURE arquivo_oportun_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 15/07/2019
  -- DESCRICAO: Adicionar arquivo na OPORTUNIDADE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         22/11/2023  Novo parametro tipo_arq_oport
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_oportunidade_id   IN arquivo_oportunidade.oportunidade_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_tipo_arq_oport    IN arquivo_oportunidade.tipo_arq_oport%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  --ALCBO_221123
  v_desc_tipo_arq VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome jurídico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_221123
  IF rtrim(p_tipo_arq_oport) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do subtipo do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_tipo_arq := util_pkg.desc_retornar('tipo_arq_oport', p_tipo_arq_oport);
  --
  IF v_desc_tipo_arq IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do subtipo de arquivo inválido (' || p_tipo_arq_oport || ').';
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'OPORTUNIDADE';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_oportunidade_id,
                        v_tipo_arquivo_id,
                        p_nome_original,
                        p_nome_fisico,
                        p_descricao,
                        p_mime_type,
                        p_tamanho,
                        p_palavras_chave,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --ALCBO_221123
  UPDATE arquivo_oportunidade
     SET tipo_arq_oport = TRIM(p_tipo_arq_oport)
   WHERE arquivo_id = p_arquivo_id;
  --
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := 'Anexação de arquivo na Oportunidade (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END arquivo_oportun_adicionar;
 --
 --
 PROCEDURE arquivo_oportun_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 15/07/2019
  -- DESCRICAO: Excluir arquivo da OPORTUNIDADE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_nome_original   arquivo.nome_original%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade         op,
         arquivo_oportunidade ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.oportunidade_id = op.oportunidade_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ao.oportunidade_id,
         ar.nome_original
    INTO v_oportunidade_id,
         v_nome_original
    FROM arquivo_oportunidade ao,
         arquivo              ar
   WHERE ao.arquivo_id = p_arquivo_id
     AND ao.arquivo_id = ar.arquivo_id;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = v_oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := 'Exclusão de arquivo da Oportunidade (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END arquivo_oportun_excluir;
 --
 --
 PROCEDURE visualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: registra o evento de visualizacao de OPORTUNIDADE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_oport   oportunidade.numero%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero
    INTO v_numero_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'VISUALIZAR',
                   v_identif_objeto,
                   p_oportunidade_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END visualizar;
 --
 --
 PROCEDURE pontencial_geracao_negocio_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 07/12/2023
  -- DESCRICAO: Gera potencial de geracao de negocio
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         12/04/2024  Ajuste variavel valor invalido
  -- Ana Luiza         11/03/2025  Inclusao p_flag_commit
  -----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_flag_sem_def_valores IN VARCHAR2,
  p_vetor_servico        IN VARCHAR2,
  p_vetor_valor          IN VARCHAR2,
  p_flag_sem_valor       IN VARCHAR2,
  p_flag_commit          IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_delimitador          CHAR(1);
  v_vetor_servico        VARCHAR(1000);
  v_vetor_valor          VARCHAR(1000);
  v_vetor_flag_sem_valor VARCHAR(1000);
  v_valor_char           VARCHAR(1000); --ALCBO_120424
  --
  v_flag_sem_valor_char VARCHAR2(20);
  --
  v_servico_id     oport_potencial.servico_id%TYPE;
  v_flag_sem_valor oport_potencial.flag_sem_valor%TYPE;
  v_servico_old    oport_potencial.servico_id%TYPE;
  v_valor          oport_potencial.valor%TYPE;
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  ---------------------------------------------------------
  --Consistencia dados entrada
  ---------------------------------------------------------
  --
  IF flag_validar(p_flag_sem_def_valores) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Sem definição de Produto e Valores inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_sem_def_valores = 'N'
  THEN
   IF p_vetor_servico IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do produto é obrigatório';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --
  /*
  SELECT COUNT(1)
  INTO   v_qt
  FROM   interacao i
  INNER  JOIN status_aux_oport sao ON i.status_aux_oport_id = sao.status_aux_oport_id
  WHERE  sao.flag_obriga_preco_manual = 'S'
  AND    i.oportunidade_id = p_oportunidade_id;
  --
  IF v_qt > 0 AND p_vetor_servico IS NULL AND p_vetor_servico IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Produto e Valor são obrigatórios';
   RAISE v_exception;
  END IF;
  */
  ----------------------------------------------------------------------------------
  --Atualizando flag_sem_preco_manual na tab oportunidade
  ----------------------------------------------------------------------------------
  UPDATE oportunidade
     SET flag_sem_preco_manual = TRIM(p_flag_sem_def_valores)
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  --
  ----------------------------------------------------------------------------------
  --Limpa dados do vetor anterior para receber novo vetor
  ----------------------------------------------------------------------------------
  DELETE oport_potencial
   WHERE oportunidade_id = p_oportunidade_id;
  --
  --
  v_delimitador          := '|';
  v_vetor_servico        := rtrim(p_vetor_servico);
  v_vetor_valor          := rtrim(p_vetor_valor);
  v_vetor_flag_sem_valor := rtrim(p_flag_sem_valor);
  --
  --
  WHILE nvl(length(rtrim(v_vetor_servico)), 0) > 0
  LOOP
   v_servico_id          := nvl(numero_converter(prox_valor_retornar(v_vetor_servico, v_delimitador)),
                                0);
   v_valor_char          := prox_valor_retornar(v_vetor_valor, v_delimitador);
   v_flag_sem_valor_char := prox_valor_retornar(v_vetor_flag_sem_valor, v_delimitador);
   --
   --
   IF nvl(length(rtrim(v_vetor_servico)), 0) > 0 AND v_flag_sem_valor_char IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Flag Sem Valor Definido é obrigatório, se não quiser informar valor, por favor marque a flag';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(v_flag_sem_valor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag Sem Valor Definido inválida.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_sem_valor_char = 'N'
   THEN
    IF p_vetor_valor IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do valor é obrigatório';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_valor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor := numero_converter(v_valor_char); --ALCBO_120424
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_potencial
    WHERE oportunidade_id = p_oportunidade_id
      AND servico_id = v_servico_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO oport_potencial
     (flag_sem_valor,
      oportunidade_id,
      servico_id,
      valor)
    VALUES
     (v_flag_sem_valor_char,
      p_oportunidade_id,
      v_servico_id,
      v_valor);
   ELSE
    UPDATE oport_potencial
       SET flag_sem_valor = v_flag_sem_valor_char,
           servico_id     = v_servico_id,
           valor          = v_valor
     WHERE oportunidade_id = p_oportunidade_id
       AND servico_id = v_servico_id;
   END IF;
  END LOOP;
  --
  FOR aux IN (SELECT cenario_id
                FROM cenario
               WHERE oportunidade_id IN (SELECT oportunidade_id
                                           FROM oportunidade
                                          WHERE oportunidade_id = p_oportunidade_id
                                            AND empresa_id = p_empresa_id))
  LOOP
   cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                  p_empresa_id,
                                  aux.cenario_id,
                                  p_erro_cod,
                                  p_erro_msg);
  END LOOP;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END pontencial_geracao_negocio_gerar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 28/02/2019
  -- DESCRICAO: Subrotina que gera o xml da OPORTUNIDADE para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_ce IS
   SELECT ce.num_cenario,
          ce.data_entrada,
          ce.nome AS nome_cenario,
          ce.num_parcelas,
          ce.coment_parcelas,
          ce.flag_padrao,
          util_pkg.desc_retornar('moeda', ce.moeda) AS moeda,
          ce.valor_cotacao,
          ce.data_cotacao
     FROM cenario ce
    WHERE ce.oportunidade_id = p_oportunidade_id
    ORDER BY ce.num_cenario;
  --
  CURSOR c_it IS
   SELECT it.data_interacao,
          it.data_entrada,
          pe.apelido AS responsavel,
          util_pkg.desc_retornar('oportunidade_meio_contato', it.meio_contato) AS meio_contato,
          it.perc_prob_fech,
          it.data_prov_fech
     FROM interacao it,
          pessoa    pe
    WHERE it.oportunidade_id = p_oportunidade_id
      AND it.usuario_resp_id = pe.usuario_id
    ORDER BY it.data_interacao;
  --
  CURSOR c_ct IS
   SELECT em.nome AS empresa,
          contrato_pkg.numero_formatar(ct.contrato_id) AS num_contrato
     FROM contrato       ct,
          empresa        em,
          oport_contrato oc
    WHERE oc.oportunidade_id = p_oportunidade_id
      AND oc.contrato_id = ct.contrato_id
      AND ct.empresa_id = em.empresa_id
    ORDER BY em.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("oportunidade_id", op.oportunidade_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_oport", op.numero),
                   xmlelement("descricao", op.nome),
                   xmlelement("solicitante", ps.apelido),
                   xmlelement("data_entrada", data_hora_mostrar(op.data_entrada)),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("contato_cliente", co.apelido),
                   xmlelement("produto_cliente", pc.nome),
                   xmlelement("flag_conflito", op.flag_conflito),
                   xmlelement("cliente_conflito", cc.apelido),
                   xmlelement("origem", util_pkg.desc_retornar('oportunidade_origem', op.origem)),
                   xmlelement("compl_origem", op.compl_origem),
                   xmlelement("tipo_negocio",
                              util_pkg.desc_retornar('oportunidade_tipo_negocio', op.tipo_negocio)),
                   xmlelement("tipo_contrato", tc.nome),
                   xmlelement("data_status", data_hora_mostrar(op.data_status)),
                   xmlelement("status_oport", op.status),
                   xmlelement("status_oport_aux", st.nome),
                   xmlelement("tipo_conc",
                              decode(op.tipo_conc, 'GAN', 'Ganha', 'PER', 'Perdida', '-')),
                   xmlelement("perda_para", op.perda_para),
                   xmlelement("motivo_status", op.motivo_status),
                   xmlelement("compl_status", op.compl_status),
                   xmlelement("valor_total", numero_mostrar(op.valor_oportun, 2, 'S')))
    INTO v_xml
    FROM oportunidade     op,
         pessoa           cl,
         pessoa           co,
         pessoa           ps,
         pessoa           cc,
         produto_cliente  pc,
         status_aux_oport st,
         tipo_contrato    tc
   WHERE op.oportunidade_id = p_oportunidade_id
     AND op.cliente_id = cl.pessoa_id
     AND op.contato_id = co.pessoa_id
     AND op.produto_cliente_id = pc.produto_cliente_id
     AND op.usuario_solic_id = ps.usuario_id(+)
     AND op.status_aux_oport_id = st.status_aux_oport_id(+)
     AND op.cliente_conflito_id = cc.pessoa_id(+)
     AND op.tipo_contrato_id = tc.tipo_contrato_id;
  --
  ------------------------------------------------------------
  -- monta CENARIOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ce IN c_ce
  LOOP
   SELECT xmlagg(xmlelement("cenario",
                            xmlelement("data_entrada", data_mostrar(r_ce.data_entrada)),
                            xmlelement("numero", r_ce.num_cenario),
                            xmlelement("nome", r_ce.nome_cenario),
                            xmlelement("num_parcelas", r_ce.num_parcelas),
                            xmlelement("coment_parcelas", r_ce.coment_parcelas),
                            xmlelement("flag_padrao", r_ce.flag_padrao),
                            xmlelement("moeda", r_ce.moeda),
                            xmlelement("valor_cotacao", numero_mostrar(r_ce.valor_cotacao, 6, 'S')),
                            xmlelement("data_cotacao", data_mostrar(r_ce.data_cotacao))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("cenarios", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta INTERACOES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_it IN c_it
  LOOP
   SELECT xmlagg(xmlelement("interacao",
                            xmlelement("data_entrada", data_mostrar(r_it.data_entrada)),
                            xmlelement("data_interacao", data_mostrar(r_it.data_interacao)),
                            xmlelement("responsavel", r_it.responsavel),
                            xmlelement("meio", r_it.meio_contato),
                            xmlelement("perc_prob_fech", numero_mostrar(r_it.perc_prob_fech, 2, 'S')),
                            xmlelement("data_prov_fech", data_mostrar(r_it.data_prov_fech))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("interacoes", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta CONTRATOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ct IN c_ct
  LOOP
   SELECT xmlagg(xmlelement("contrato",
                            xmlelement("empresa", r_ct.empresa),
                            xmlelement("contrato", r_ct.num_contrato)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("contratos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "oportunidade"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("oportunidade", v_xml))
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END xml_gerar;
 --
 --
 FUNCTION data_termino_contrato_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind     DATA: 23/11/2023
  -- DESCRICAO: calcula a data término do contrato a ser aberto no ganhar da Oportunidade
  --            em função da data de início e duração dos serviços (Produtos) do Cenário
  --            indicado como escolhido em relação à nova data de início fornecida
  --            pelo usuário
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_cenario_id       IN cenario.cenario_id%TYPE,
  p_vetor_servico_id IN VARCHAR2,
  p_data_inicio      IN VARCHAR2
 ) RETURN VARCHAR2 IS
  v_vetor_srv_servico_id  VARCHAR2(1000);
  v_data_inicio_ori       DATE;
  v_data_termino_ori      DATE;
  v_data_termino_contrato VARCHAR2(100);
  v_qt                    INT;
  v_meses_diferenca       INT;
  v_dias_diferenca        INT;
  v_data_inicio           DATE;
  v_data_inicio01         DATE;
 BEGIN
  --verifica se o cenário existe e possui serviços com data de início e duração
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario c
   INNER JOIN cenario_servico s
      ON s.cenario_id = c.cenario_id
   WHERE c.cenario_id = p_cenario_id
     AND s.mes_ano_inicio IS NOT NULL
     AND s.duracao_meses IS NOT NULL;
  --
  IF data_validar(p_data_inicio) = 0 OR v_qt = 0 OR TRIM(p_data_inicio) IS NULL OR
     TRIM(p_vetor_servico_id) IS NULL
  THEN
   --se o cenário não existe ou não possui data de inicio e duração em seus produtos
   --ou a data de inicio fornecida está nula ou o vetor de servico fornecido está
   --nulo, sai da função com o varchar2 vazio, sem dar mensagem de erro
   v_data_termino_contrato := '';
  ELSE
   v_data_inicio := data_converter(p_data_inicio);
   --
   v_vetor_srv_servico_id := ',' || REPLACE(TRIM(p_vetor_servico_id), '|', ',') || ',';
   --
   --recupera datas de inicio e término originais definidas
   --na precificação de acordo com datas de inicio e duração
   --dos produtos previamente definidos
   SELECT add_months(MIN(s.mes_ano_inicio), 0),
          add_months(MAX(add_months(s.mes_ano_inicio, s.duracao_meses) - 1), 0)
     INTO v_data_inicio_ori,
          v_data_termino_ori
     FROM cenario_servico s
    WHERE s.cenario_id = p_cenario_id
      AND instr(v_vetor_srv_servico_id, ',' || s.servico_id || ',') > 0;
   --
   --criar variável com data fornecida com base no dia 01 para cálculo de diferença de meses
   v_data_inicio01 := to_date('01/' || extract(MONTH FROM v_data_inicio) || '/' ||
                              extract(YEAR FROM v_data_inicio),
                              'dd/mm/yyyy');
   --criar variável com diferença de meses para adequação da data término
   v_meses_diferenca := months_between(v_data_inicio01, v_data_inicio_ori);
   --criar variável com diferença de dias para adequação da data término
   v_dias_diferenca := v_data_inicio - v_data_inicio01;
   --
   --adequa a data término, mantendo o intervalo original em meses sugerido para o contrato
   --de acordo com a nova data de início fornecida
   v_data_termino_contrato := to_char(add_months(v_data_termino_ori, v_meses_diferenca) +
                                      v_dias_diferenca,
                                      'dd/mm/yyyy');
   --
  END IF;
  --
  RETURN v_data_termino_contrato;
 END data_termino_contrato_calcular;
 --
--
END; -- OPORTUNIDADE_PKG

/
