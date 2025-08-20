--------------------------------------------------------
--  DDL for Package Body RAFAEL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "RAFAEL_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: SIlvia          ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: Inclus�o de CONDICAO_PAGTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2013  Novo parametro cod_ext_condicao
  -- Silvia            01/02/2021  Novos parametros para regras
  -- Ana Luiza         06/12/2024  Novo parametro ordem
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_nome             IN condicao_pagto.nome%TYPE,
  p_descricao        IN condicao_pagto.descricao%TYPE,
  p_codigo           IN condicao_pagto.codigo%TYPE,
  p_cod_ext_condicao IN condicao_pagto.cod_ext_condicao%TYPE,
  p_tipo_regra       IN condicao_pagto.tipo_regra%TYPE,
  p_vetor_dia_semana IN VARCHAR2,
  p_semana_mes       IN VARCHAR2,
  p_dia_util_mes     IN VARCHAR2,
  p_flag_pag_for     IN VARCHAR2,
  p_flag_fat_cli     IN VARCHAR2,
  p_flag_ativo       IN VARCHAR2,
  p_vetor_valor_perc IN VARCHAR2,
  p_vetor_num_dias   IN VARCHAR2,
  p_ordem            IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_delimitador       CHAR(1);
  v_vetor_dia_semana  LONG;
  v_vetor_valor_perc  LONG;
  v_vetor_num_dias    LONG;
  v_valor_perc_char   VARCHAR2(20);
  v_num_dias_char     VARCHAR2(20);
  v_condicao_pagto_id condicao_pagto.condicao_pagto_id%TYPE;
  v_dia_util_mes      condicao_pagto.dia_util_mes%TYPE;
  v_semana_mes        condicao_pagto.semana_mes%TYPE;
  v_somatoria         NUMBER;
  v_num_parcela       condicao_pagto_det.num_parcela%TYPE;
  v_valor_perc        condicao_pagto_det.valor_perc%TYPE;
  v_num_dias          condicao_pagto_det.num_dias%TYPE;
  v_num_dias_ant      condicao_pagto_det.num_dias%TYPE;
  v_dia_semana_id     dia_semana.dia_semana_id%TYPE;
  v_ordem             condicao_pagto.ordem%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_id, 'CONDICAO_PAGTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Voc� n�o tem privil�gio para realizar essa opera��o.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do c�digo � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  -- SR (sem regra); DS (nos dias da semana indicados);
  -- DU (no N dia util do mes)
  IF TRIM(p_tipo_regra) IS NULL OR p_tipo_regra NOT IN ('SR', 'DS', 'DU') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de regra inv�lido (' || p_tipo_regra || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_semana_mes) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Semana do m�s inv�lida (' || p_semana_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  v_semana_mes := nvl(to_number(p_semana_mes), 0);
  --
  IF v_semana_mes < 0 OR v_semana_mes > 4 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Semana do m�s inv�lida (' || p_semana_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_dia_util_mes) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia �til do m�s inv�lido (' || p_dia_util_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  v_dia_util_mes := nvl(to_number(p_dia_util_mes), 0);
  --
  IF v_dia_util_mes < 0 OR v_dia_util_mes > 15 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia �til do m�s inv�lido (' || p_dia_util_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_regra = 'DS' AND TRIM(p_vetor_dia_semana) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de regra, pelo menos um dia da semana deve ser indicado.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_regra = 'DU' AND v_dia_util_mes <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de regra, o dia �til do m�s deve ser indicado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inv�lido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pag_for) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pagamentos de fornecedores inv�lido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_fat_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag faturas de clientes inv�lido.';
   RAISE v_exception;
  END IF;
  --ALCBO_061224
  v_ordem := nvl(to_number(p_ordem), 0);
  ------------------------------------------------------------
  -- verificacao de chave duplicada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE upper(nome) = upper(p_nome)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome j� existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE upper(codigo) = upper(p_codigo)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse c�digo j� existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_condicao_pagto.nextval
    INTO v_condicao_pagto_id
    FROM dual;
  --
  INSERT INTO condicao_pagto
   (condicao_pagto_id,
    empresa_id,
    codigo,
    nome,
    descricao,
    cod_ext_condicao,
    tipo_regra,
    semana_mes,
    dia_util_mes,
    flag_ativo,
    flag_pag_for,
    flag_fat_cli,
    ordem)
  VALUES
   (v_condicao_pagto_id,
    p_empresa_id,
    upper(TRIM(p_codigo)),
    TRIM(p_nome),
    TRIM(p_descricao),
    TRIM(p_cod_ext_condicao),
    TRIM(p_tipo_regra),
    zvl(v_semana_mes, NULL),
    zvl(v_dia_util_mes, NULL),
    p_flag_ativo,
    p_flag_pag_for,
    p_flag_fat_cli,
    v_ordem);
  --
  v_num_parcela  := 0;
  v_somatoria    := 0;
  v_num_dias_ant := -10;
  --
  ------------------------------------------------------------
  -- atualizacao das parcelas
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_valor_perc := p_vetor_valor_perc;
  v_vetor_num_dias   := p_vetor_num_dias;
  --
  WHILE nvl(length(rtrim(v_vetor_valor_perc)), 0) > 0
  LOOP
   v_valor_perc_char := prox_valor_retornar(v_vetor_valor_perc, v_delimitador);
   v_num_dias_char   := prox_valor_retornar(v_vetor_num_dias, v_delimitador);
   --
   IF numero_validar(v_valor_perc_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de percentual inv�lido (' || v_valor_perc_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(v_num_dias_char) = 0 OR to_number(v_num_dias_char) > 99999 OR
      to_number(v_num_dias_char) < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'N�mero de dias inv�lido (' || v_num_dias_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_perc := nvl(numero_converter(v_valor_perc_char), 0);
   v_num_dias   := nvl(to_number(v_num_dias_char), 0);
   --
   IF v_valor_perc > 0 THEN
    IF v_num_dias <= v_num_dias_ant THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Os n�meros de dias das parcelas devem ser crescentes.';
     RAISE v_exception;
    END IF;
    --
    v_num_dias_ant := v_num_dias;
    v_num_parcela  := v_num_parcela + 1;
    --
    INSERT INTO condicao_pagto_det
     (condicao_pagto_id,
      num_parcela,
      valor_perc,
      num_dias)
    VALUES
     (v_condicao_pagto_id,
      v_num_parcela,
      v_valor_perc,
      v_num_dias);
   END IF;
   --
   v_somatoria := v_somatoria + v_valor_perc;
  END LOOP;
  --
  IF abs(v_somatoria - 100) > 0.0008 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As parcelas precisam somar 100%.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao dos dias da semana
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_dia_semana := p_vetor_dia_semana;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana, v_delimitador)), 0);
   --
   IF v_dia_semana_id > 0 THEN
    INSERT INTO condicao_pagto_dia
     (condicao_pagto_id,
      dia_semana_id)
    VALUES
     (v_condicao_pagto_id,
      v_dia_semana_id);
   END IF;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;

 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: Atualiza��o de CONDICAO_PAGTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2013  Novo parametro cod_ext_condicao
  -- Silvia            01/02/2021  Novos parametros para regras
  -- Ana Luiza         06/12/2024  Novo parametro ordem
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_nome              IN condicao_pagto.nome%TYPE,
  p_descricao         IN condicao_pagto.descricao%TYPE,
  p_codigo            IN condicao_pagto.codigo%TYPE,
  p_cod_ext_condicao  IN condicao_pagto.cod_ext_condicao%TYPE,
  p_tipo_regra        IN condicao_pagto.tipo_regra%TYPE,
  p_vetor_dia_semana  IN VARCHAR2,
  p_semana_mes        IN VARCHAR2,
  p_dia_util_mes      IN VARCHAR2,
  p_flag_pag_for      IN VARCHAR2,
  p_flag_fat_cli      IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_vetor_valor_perc  IN VARCHAR2,
  p_vetor_num_dias    IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_dia_semana LONG;
  v_vetor_valor_perc LONG;
  v_vetor_num_dias   LONG;
  v_valor_perc_char  VARCHAR2(20);
  v_num_dias_char    VARCHAR2(20);
  v_dia_util_mes     condicao_pagto.dia_util_mes%TYPE;
  v_semana_mes       condicao_pagto.semana_mes%TYPE;
  v_somatoria        NUMBER;
  v_num_parcela      condicao_pagto_det.num_parcela%TYPE;
  v_valor_perc       condicao_pagto_det.valor_perc%TYPE;
  v_num_dias         condicao_pagto_det.num_dias%TYPE;
  v_num_dias_ant     condicao_pagto_det.num_dias%TYPE;
  v_dia_semana_id    dia_semana.dia_semana_id%TYPE;
  v_ordem            condicao_pagto.ordem%TYPE;
  v_codigo_old       condicao_pagto.codigo%TYPE;
  v_nome_old         condicao_pagto.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa condi��o de pagamento n�o existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_id, 'CONDICAO_PAGTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Voc� n�o tem privil�gio para realizar essa opera��o.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do c�digo � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ordem � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  -- SR (sem regra); DS (nos dias da semana indicados);
  -- DU (no N dia util do mes)
  IF TRIM(p_tipo_regra) IS NULL OR p_tipo_regra NOT IN ('SR', 'DS', 'DU') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de regra inv�lido (' || p_tipo_regra || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_semana_mes) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Semana do m�s inv�lida (' || p_semana_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  v_semana_mes := nvl(to_number(p_semana_mes), 0);
  --
  IF v_semana_mes < 0 OR v_semana_mes > 4 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Semana do m�s inv�lida (' || p_semana_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_dia_util_mes) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia �til do m�s inv�lido (' || p_dia_util_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  v_dia_util_mes := nvl(to_number(p_dia_util_mes), 0);
  --
  IF v_dia_util_mes < 0 OR v_dia_util_mes > 15 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia �til do m�s inv�lido (' || p_dia_util_mes || '.)';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_regra = 'DS' AND TRIM(p_vetor_dia_semana) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de regra, pelo menos um dia da semana deve ser indicado.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_regra = 'DU' AND v_dia_util_mes <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de regra, o dia �til do m�s deve ser indicado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inv�lido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pag_for) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pagamentos de fornecedores inv�lido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_fat_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag faturas de clientes inv�lido.';
   RAISE v_exception;
  END IF;
  --ALCBO_061224
  v_ordem := nvl(to_number(p_ordem), 0);
  ------------------------------------------------------------
  -- verificacao de chave duplicada
  ------------------------------------------------------------  
  -- Recuperando o valor atual do nome e c�digo antes da verifica��o de duplicidade
  SELECT nome,
         codigo
    INTO v_nome_old,
         v_codigo_old
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND empresa_id = p_empresa_id;
  -- Verificando se o nome foi alterado
  IF upper(p_nome) <> upper(v_nome_old) THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM condicao_pagto
    WHERE condicao_pagto_id <> p_condicao_pagto_id
      AND empresa_id = p_empresa_id
      AND upper(nome) = upper(p_nome);
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse nome j� existe.';
    RAISE v_exception;
   END IF;
  END IF;
  -- Verificando se o c�digo foi alterado
  IF upper(p_codigo) <> upper(v_codigo_old) THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM condicao_pagto
    WHERE condicao_pagto_id <> p_condicao_pagto_id
      AND empresa_id = p_empresa_id
      AND upper(codigo) = upper(p_codigo);
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse c�digo j� existe.' || v_codigo_old || ' | ' || p_codigo;
    RAISE v_exception;
   END IF;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE condicao_pagto
     SET codigo           = upper(TRIM(p_codigo)),
         nome             = TRIM(p_nome),
         descricao        = TRIM(p_descricao),
         cod_ext_condicao = TRIM(p_cod_ext_condicao),
         tipo_regra       = TRIM(p_tipo_regra),
         semana_mes       = zvl(v_semana_mes, NULL),
         dia_util_mes     = zvl(v_dia_util_mes, NULL),
         flag_ativo       = p_flag_ativo,
         flag_pag_for     = p_flag_pag_for,
         flag_fat_cli     = p_flag_fat_cli,
         ordem            = v_ordem
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  ------------------------------------------------------------
  -- atualizacao das parcelas
  ------------------------------------------------------------
  DELETE FROM condicao_pagto_det
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  v_num_parcela  := 0;
  v_somatoria    := 0;
  v_num_dias_ant := -10;
  --
  v_delimitador      := '|';
  v_vetor_valor_perc := p_vetor_valor_perc;
  v_vetor_num_dias   := p_vetor_num_dias;
  --
  WHILE nvl(length(rtrim(v_vetor_valor_perc)), 0) > 0
  LOOP
   v_valor_perc_char := prox_valor_retornar(v_vetor_valor_perc, v_delimitador);
   v_num_dias_char   := prox_valor_retornar(v_vetor_num_dias, v_delimitador);
   --
   IF numero_validar(v_valor_perc_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de percentual inv�lido (' || v_valor_perc_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(v_num_dias_char) = 0 OR to_number(v_num_dias_char) > 99999 OR
      to_number(v_num_dias_char) < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'N�mero de dias inv�lido (' || v_num_dias_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_perc := nvl(numero_converter(v_valor_perc_char), 0);
   v_num_dias   := nvl(to_number(v_num_dias_char), 0);
   --
   IF v_valor_perc > 0 THEN
    IF v_num_dias <= v_num_dias_ant THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Os n�meros de dias das parcelas devem ser crescentes.';
     RAISE v_exception;
    END IF;
    --
    v_num_dias_ant := v_num_dias;
    v_num_parcela  := v_num_parcela + 1;
    --
    INSERT INTO condicao_pagto_det
     (condicao_pagto_id,
      num_parcela,
      valor_perc,
      num_dias)
    VALUES
     (p_condicao_pagto_id,
      v_num_parcela,
      v_valor_perc,
      v_num_dias);
   END IF;
   --
   v_somatoria := v_somatoria + v_valor_perc;
  END LOOP;
  --
  IF abs(v_somatoria - 100) > 0.0008 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As parcelas precisam somar 100%.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao dos dias da semana
  ------------------------------------------------------------
  DELETE FROM condicao_pagto_dia
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  v_delimitador      := '|';
  v_vetor_dia_semana := p_vetor_dia_semana;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana, v_delimitador)), 0);
   --
   IF v_dia_semana_id > 0 THEN
    INSERT INTO condicao_pagto_dia
     (condicao_pagto_id,
      dia_semana_id)
    VALUES
     (p_condicao_pagto_id,
      v_dia_semana_id);
   END IF;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: Exclus�o de CONDICAO_PAGTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2013  Consistencia de carta acordo
  -- Silvia            01/02/2021  Implementacao de regras
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_codigo    condicao_pagto.codigo%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa condi��o de pagamento n�o existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_id, 'CONDICAO_PAGTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Voc� n�o tem privil�gio para realizar essa opera��o.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa condi��o de pagamento est� sendo referenciada por carta acordo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM condicao_pagto_det
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  DELETE FROM condicao_pagto_dia
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  DELETE FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- excluir
 --
 --
 FUNCTION data_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 15/02/2021
  -- DESCRICAO: retorna a data processada de acordo com a regra da condicao de pagamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_data              IN DATE
 ) RETURN DATE AS
  v_qt            INTEGER;
  v_retorno       DATE;
  v_saida         EXCEPTION;
  v_tipo_regra    condicao_pagto.tipo_regra%TYPE;
  v_semana_mes    condicao_pagto.semana_mes%TYPE;
  v_semana_refer  condicao_pagto.semana_mes%TYPE;
  v_dia_util_mes  condicao_pagto.dia_util_mes%TYPE;
  v_data_refer    DATE;
  v_data_prim_dia DATE;
  v_data_dia_util DATE;
  v_data          DATE;
  v_achou         INTEGER;
  v_dia_semana    INTEGER;
  --
 BEGIN
  v_retorno    := NULL;
  v_data_refer := trunc(p_data);
  --
  IF p_data IS NULL OR nvl(p_condicao_pagto_id, 0) = 0 OR nvl(p_usuario_id, 0) = 0 THEN
   -- parametros inconsistentes
   v_retorno := NULL;
   RAISE v_saida;
  END IF;
  --
  SELECT tipo_regra,
         semana_mes,
         dia_util_mes
    INTO v_tipo_regra,
         v_semana_mes,
         v_dia_util_mes
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  IF v_tipo_regra = 'SR' THEN
   -- sem regra. Retorna a mesma data.
   v_retorno := p_data;
   RAISE v_saida;
  END IF;
  --
  IF v_tipo_regra = 'DU' THEN
   -- regra do dia util do mes.
   -- pega o primeiro dia do mes
   v_data_prim_dia := data_converter('01/' || to_char(v_data_refer, 'MM/YYYY'));
   -- soma os N dias uteis especificados na regra
   v_data_dia_util := feriado_pkg.prox_dia_util_retornar(p_usuario_id,
                                                         v_data_prim_dia - 1,
                                                         v_dia_util_mes,
                                                         'N');
   --
   IF v_data_dia_util >= v_data_refer THEN
    -- o dia util calculado serve.
    v_retorno := v_data_dia_util;
   ELSE
    -- precisa avancar um mes
    v_data_prim_dia := add_months(v_data_prim_dia, 1);
    -- soma os N dias uteis especificados na regra
    v_data_dia_util := feriado_pkg.prox_dia_util_retornar(p_usuario_id,
                                                          v_data_prim_dia - 1,
                                                          v_dia_util_mes,
                                                          'N');
    v_retorno       := v_data_dia_util;
   END IF;
  END IF; -- fim do IF v_tipo_regra = 'DU'
  --
  IF v_tipo_regra = 'DS' THEN
   -- regra do dia da semana.
   v_achou := 0;
   v_data  := v_data_refer;
   WHILE v_achou = 0
   LOOP
    v_dia_semana := to_char(v_data, 'D');
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM condicao_pagto_dia cp,
           dia_semana         ds
     WHERE cp.condicao_pagto_id = p_condicao_pagto_id
       AND cp.dia_semana_id = ds.dia_semana_id
       AND ds.ordem = v_dia_semana;
    --
    IF v_qt > 0 THEN
     -- o dia da semana serve. Verifica o nro da semana.
     IF nvl(v_semana_mes, 0) BETWEEN 1 AND 4 THEN
      -- precisa ser na semana certa do mes.
      v_semana_refer := to_char(v_data, 'W');
      --v_data_prim_dia := data_converter('01/'|| TO_CHAR(v_data,'MM/YYYY'));
      --v_semana_refer := TO_NUMBER(TO_CHAR(v_data,'IW')) - TO_NUMBER(TO_CHAR(v_data_prim_dia,'IW')) +1;
      --
      IF v_semana_refer > 4 THEN
       -- se a data cai na 5 ou 6 semana do mes, considera como 4
       v_semana_refer := 4;
      END IF;
      --
      IF v_semana_refer = v_semana_mes THEN
       -- a semana bate
       v_retorno := v_data;
       v_achou   := 1;
      END IF;
     ELSE
      -- nao precisa verificar o nro da semana. A data serve
      v_retorno := v_data;
      v_achou   := 1;
     END IF;
    END IF;
    --
    v_data := v_data + 1;
   END LOOP;
  END IF; -- fim do IF v_tipo_regra = 'DS'
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_retornar;
 --
 --
 --
 /*
  Licoes de casa:
  1. Criar uma procedure q conter� 4 parametros. Vou entrar com a informa��o do usuario_id e quero que ela me retorne o nome, login fun��o do usu�rio. A sa�da deve ser impressa em tela.(Usar tab usuario e tab pessoa). Caso n�o venha preenchido a fun��o do usu�rio colocar texto 'Sem Fun��o'
 --
 --
  ex de sa�da:
  Nome Usu�rio: Nuvo Vindi
  Login Usu�rio: nuvo.vindi
  Fun��o Usu�rio: Time Sheet 
 --
 --
  2. Criar uma fun��o com dois parametros de entrada(usuario_id e nome) ela deve comparar se o nome que eu informei existe ou n�o na tabela de pessoa essa fun��o deve retornar um texto se foi Encontrado ou n�o encontrado.
  */
 ----Exercicio 1
 --
 --
 PROCEDURE info_usuarios_mostrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael          ProcessMind     DATA: 14/01/2025
  -- DESCRICAO: Procedure que retorna informa��es do Usu�rio a partir de seu usuario_id
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_nome       OUT VARCHAR2,
  p_login      OUT VARCHAR2,
  p_funcao     OUT VARCHAR2,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) AS
  v_qt INTEGER;
 BEGIN
  -- Verifica se o usu�rio existe
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa pe
    LEFT JOIN usuario usu
      ON usu.usuario_id = pe.usuario_id
   WHERE usu.usuario_id = p_usuario_id;
  IF v_qt <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usu�rio n�o existe.';
   RETURN; -- Finaliza a procedure caso o usu�rio n�o seja encontrado
  END IF;
  -- Busca as informa��es do usu�rio
  SELECT pe.nome,
         nvl(pe.funcao, 'Sem Fun��o'),
         usu.login
    INTO p_nome,
         p_funcao,
         p_login
    FROM pessoa pe
    LEFT JOIN usuario usu
      ON usu.usuario_id = pe.usuario_id
   WHERE usu.usuario_id = p_usuario_id;
 END info_usuarios_mostrar;
 --
 --
 --- Exercicio 2:
 ---> 
 FUNCTION verificar_nome_pessoa
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael          ProcessMind     DATA: 13/01/2025
  -- DESCRICAO: Fun��o que Compara "NOME E USUARIO_ID" e retorna se 1 Encontrado e 0 N�o Encontrado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_nome       IN pessoa.nome%TYPE
 ) RETURN INTEGER IS
  v_count NUMBER;
 BEGIN
  -- Conta o n�mero de registros que correspondem aos crit�rios
  SELECT COUNT(*)
    INTO v_count
    FROM usuario usu
    LEFT JOIN pessoa pe
      ON pe.usuario_id = usu.usuario_id
   WHERE usu.usuario_id = p_usuario_id
     AND pe.nome = p_nome;
  -- Verifica se foi encontrado ou n�o
  IF v_count > 0 THEN
   RETURN 1;
  ELSE
   RETURN 0;
  END IF;
 END; --- Fim Function verificar_nome_pessoa

 --EXERC�CIO 3:
 /*
 criar uma fun��o que realize opera��es b�sicas (soma, subtra��o, multiplica��o e divis�o) entre dois n�meros fornecidos pelo usu�rio. Dependendo da opera��o escolhida, a fun��o deve retornar o resultado adequado.
 */
 --------------------------------------------------------------------------------------------------
 --
 FUNCTION calcular_operacao
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael          ProcessMind     DATA: 13/01/2025
  -- DESCRICAO: Fun��o que realize opera��es b�sicas (soma, subtra��o, multiplica��o e divis�o) entre dois n�meros fornecidos pelo usu�rio. Dependendo da opera��o escolhida, a fun��o deve retornar o resultado adequado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_num_1    IN NUMBER,
  p_num_2    IN NUMBER,
  p_operacao IN VARCHAR2
 ) RETURN NUMBER IS
  v_resultado NUMBER;
 BEGIN
 
  -- Verifica se a opera��o � por nome (soma, subtracao, multiplicacao, divisao)
  IF p_operacao = 'soma' OR p_operacao = '+' THEN
   v_resultado := p_num_1 + p_num_2;
  ELSIF p_operacao = 'subtracao' OR p_operacao = '-' THEN
   v_resultado := p_num_1 - p_num_2;
  ELSIF p_operacao = 'multiplicacao' OR p_operacao = '*' THEN
   v_resultado := p_num_1 * p_num_2;
  ELSIF p_operacao = 'divisao' OR p_operacao = '/' THEN
   IF p_num_2 = 0 THEN
    raise_application_error(-20001, 'N�o � poss�vel dividir por zero.');
   ELSE
    v_resultado := p_num_1 / p_num_2;
   END IF;
  ELSE
   raise_application_error(-20002,
                           'Opera��o inv�lida. Escolha entre soma, subtracao, multiplicacao ou divisao.');
  END IF;
 
  -- Retorna o resultado da opera��o
  RETURN v_resultado;
 
 END; --- calcular_operacao
 --
 --EXERC�CIO 4:
 /*
 desenvolver um procedimento que receba um n�mero de telefone e o formate automaticamente, adicionando os par�nteses, h�fens e espa�os corretos.
 --
 A fun��o dever�:
 --
 Receber um n�mero de telefone como entrada no formato n�o formatado (ex: "14981329897").
 Processar esse n�mero e format�-lo de acordo com o padr�o de n�meros no Brasil (ex: "(14) 98132-9897").
 Exibir o n�mero original e o n�mero formatado.
 */
 --
 PROCEDURE telefone_formatar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael          ProcessMind     DATA: 14/01/2025
  -- DESCRICAO: Procedure que retorna o n�mero de telefone no formato brasileiro (XX) XXXXX-XXXX
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_telefone           IN VARCHAR2,
  p_telefone_formatado OUT VARCHAR2
 ) AS
 
 BEGIN
  -- Serve Para Limpar os caracteres n�o n�mericos
  p_telefone_formatado := p_telefone;
  p_telefone_formatado := regexp_replace(p_telefone, '[^0-9]', '');
 
  -- Verificar se o n�mero tem 11 N�meros (Padrao de celular)
  IF length(p_telefone) = 11 THEN
   p_telefone_formatado := '(' || substr(p_telefone, 1, 2) || ') ' || substr(p_telefone, 3, 5) || '-' ||
                           substr(p_telefone, 8, 4);
  ELSE
   -- Caso o n�mero n�o tenha o tamanho correto
   p_telefone_formatado := 'N�mero inv�lido';
  END IF;
 
 END; -- telefone_formatar
 --
 /*
 -------------------------------------------------------------------------------------------------
 --EXERC�CIO 5:
 Criar uma procedure que calcule a tabuada de um n�mero, de 1 a 10 (Obrigat�rio usar LOOP).
 Sa�da Esperada para 5:
 Tabuada de 5: 5 * 1 = 5
 Tabuada de 5: 5 * 2 = 10
 */

 PROCEDURE calcular_tabuada
 (
  p_numero    IN NUMBER,
  p_resultado OUT VARCHAR2
 ) IS
  v_resultado VARCHAR2(4000);
 BEGIN
  FOR i IN 1 .. 10
  LOOP
   v_resultado := v_resultado || p_numero || ' x ' || i || ' = ' || '[' || (p_numero * i) || '] ' ||
                  chr(10);
  END LOOP;
  p_resultado := v_resultado;
 END; -- calcular_tabuada
 -------------------------------------------------------------------------------------------------
 --EXERC�CIO 6:
 /*
 Criar uma procedure que, com um n�mero fornecido como entrada, imprima uma sequ�ncia de n�meros de 1 at� esse n�mero. Por exemplo, se o n�mero fornecido for 5, a sa�da deve ser: 1 2 3 4 5.
 */
 --
 PROCEDURE imprimir_sequencia
 (
  p_numero    IN NUMBER,
  p_sequencia OUT VARCHAR
 ) IS
  v_sequencia VARCHAR(4000);
 BEGIN
  v_sequencia := '';
 
  FOR i IN 1 .. p_numero
  LOOP
   v_sequencia := v_sequencia || i || ' ';
  END LOOP;
 
  p_sequencia := TRIM(v_sequencia);
 END imprimir_sequencia;

--
END; -- CONDICAO_PAGTO_PKG

/
