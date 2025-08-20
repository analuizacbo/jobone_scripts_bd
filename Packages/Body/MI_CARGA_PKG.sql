--------------------------------------------------------
--  DDL for Package Body MI_CARGA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "MI_CARGA_PKG" IS
 --
 --
 PROCEDURE arquivo_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/06/2019
  -- DESCRICAO: registra a carga de um arquivo na tabela MI_CARGA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_tipo              IN VARCHAR2,
  p_arquivo           IN VARCHAR2,
  p_mi_carga_id       OUT mi_carga.mi_carga_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt           INTEGER;
  v_ok           INTEGER;
  v_exception    EXCEPTION;
  v_mi_carga_id  mi_carga.mi_carga_id%TYPE;
  v_ano          mi_carga.ano%TYPE;
  v_descricao    mi_carga.descricao%TYPE;
  v_nome_usuario mi_carga.nome_usuario%TYPE;
  --
 BEGIN
  p_mi_carga_id := 0;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_nome_usuario IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF TRIM(p_tipo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TIPO obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_tipo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TIPO não pode ter mais que 100 caracteres (' || p_tipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo) NOT IN ('MI_PI', 'MI_METAS') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo tipo inválido (' || p_tipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_arquivo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo ARQUIVO obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_arquivo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo ARQUIVO não pode ter mais que 100 caracteres (' || p_arquivo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo) = 'MI_PI' THEN
   v_descricao := 'Carga de PI';
  ELSIF TRIM(p_tipo) = 'MI_METAS' THEN
   v_descricao := 'Carga de Metas';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_carga.nextval
    INTO v_mi_carga_id
    FROM dual;
  --
  INSERT INTO mi_carga
   (mi_carga_id,
    empresa_id,
    usuario_id,
    nome_usuario,
    ano,
    data_carga,
    descricao,
    tipo,
    arquivo)
  VALUES
   (v_mi_carga_id,
    p_empresa_id,
    p_usuario_sessao_id,
    v_nome_usuario,
    v_ano,
    SYSDATE,
    v_descricao,
    TRIM(p_tipo),
    TRIM(p_arquivo));
  --
  COMMIT;
  p_mi_carga_id := v_mi_carga_id;
  p_erro_cod    := '00000';
  p_erro_msg    := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END arquivo_carregar;
 --
 --
 PROCEDURE metas_ooh_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/06/2019
  -- DESCRICAO: limpa tabela MI_METAS_OOH.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_ano       mi_metas_ooh.ano%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_metas_ooh
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_ooh_limpar;
 --
 --
 PROCEDURE metas_ooh_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/06/2019
  -- DESCRICAO: carrega tabela MI_METAS_OOH
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
  p_ano               IN VARCHAR2,
  p_veiculo           IN VARCHAR2,
  p_praca             IN VARCHAR2,
  p_formato           IN VARCHAR2,
  p_periodicidade     IN VARCHAR2,
  p_valor_unit_neg    IN VARCHAR2,
  p_perc_negoc        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt              INTEGER;
  v_ok              INTEGER;
  v_exception       EXCEPTION;
  v_mi_metas_ooh_id mi_metas_ooh.mi_metas_ooh_id%TYPE;
  v_ano             mi_metas_ooh.ano%TYPE;
  v_praca           mi_metas_ooh.praca%TYPE;
  v_veiculo         mi_metas_ooh.veiculo%TYPE;
  v_valor_unit_neg  mi_metas_ooh.valor_unit_neg%TYPE;
  v_perc_negoc      mi_metas_ooh.perc_negoc%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF length(TRIM(p_veiculo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VEICULO não pode ter mais que 100 caracteres (' || p_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_veiculo := TRIM(upper(acento_retirar(p_veiculo)));
  v_veiculo := TRIM(REPLACE(v_veiculo, '  ', ' '));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'ACTION OOH', 'ACTION'));
  --
  IF length(TRIM(p_praca)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA não pode ter mais que 100 caracteres (' || p_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_praca := upper(TRIM(REPLACE(p_praca, '  ', ' ')));
  --
  IF length(TRIM(p_formato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FORMATO não pode ter mais que 100 caracteres (' || p_formato || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_periodicidade)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PERIODICIDADE não pode ter mais que 100 caracteres (' ||
                 p_periodicidade || ').';
   RAISE v_exception;
  END IF;
  --
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_neg) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_NEG inválido (' || p_valor_unit_neg || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_neg := round(mi_carga_pkg.numero_converter(p_valor_unit_neg), 4);
  --
  IF mi_carga_pkg.numero_validar(p_perc_negoc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PERC_NEGOC inválido (' || p_perc_negoc || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_negoc := mi_carga_pkg.numero_converter(p_perc_negoc);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_metas_ooh.nextval
    INTO v_mi_metas_ooh_id
    FROM dual;
  --
  INSERT INTO mi_metas_ooh
   (mi_metas_ooh_id,
    empresa_id,
    mi_carga_id,
    ano,
    data_carga,
    veiculo,
    praca,
    formato,
    periodicidade,
    valor_unit_neg,
    perc_negoc,
    flag_sem_meta)
  VALUES
   (v_mi_metas_ooh_id,
    p_empresa_id,
    p_mi_carga_id,
    v_ano,
    SYSDATE,
    v_veiculo,
    v_praca,
    upper(TRIM(p_formato)),
    upper(TRIM(p_periodicidade)),
    v_valor_unit_neg,
    v_perc_negoc,
    'N');
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_ooh_carregar;
 --
 --
 PROCEDURE metas_ooh_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/06/2019
  -- DESCRICAO: calcula demais campos da tabela MI_METAS_OOH.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                     INTEGER;
  v_ok                     INTEGER;
  v_exception              EXCEPTION;
  v_ano                    mi_metas_ooh.ano%TYPE;
  v_valor_unit_neg_real    mi_metas_ooh.valor_unit_neg_real%TYPE;
  v_perc_negoc_real        mi_metas_ooh.perc_negoc_real%TYPE;
  v_valor_unit_neg_q1_real mi_metas_ooh.valor_unit_neg_q1_real%TYPE;
  v_valor_unit_neg_q2_real mi_metas_ooh.valor_unit_neg_q2_real%TYPE;
  v_valor_unit_neg_q3_real mi_metas_ooh.valor_unit_neg_q3_real%TYPE;
  v_valor_unit_neg_q4_real mi_metas_ooh.valor_unit_neg_q4_real%TYPE;
  v_perc_negoc_q1_real     mi_metas_ooh.perc_negoc_q1_real%TYPE;
  v_perc_negoc_q2_real     mi_metas_ooh.perc_negoc_q2_real%TYPE;
  v_perc_negoc_q3_real     mi_metas_ooh.perc_negoc_q3_real%TYPE;
  v_perc_negoc_q4_real     mi_metas_ooh.perc_negoc_q4_real%TYPE;
  v_valor_abs_neg_q1_real  mi_metas_ooh.valor_abs_neg_q1_real%TYPE;
  v_valor_abs_neg_q2_real  mi_metas_ooh.valor_abs_neg_q2_real%TYPE;
  v_valor_abs_neg_q3_real  mi_metas_ooh.valor_abs_neg_q3_real%TYPE;
  v_valor_abs_neg_q4_real  mi_metas_ooh.valor_abs_neg_q4_real%TYPE;
  v_valor_abs_neg_q1_meta  mi_metas_ooh.valor_abs_neg_q1_meta%TYPE;
  v_valor_abs_neg_q2_meta  mi_metas_ooh.valor_abs_neg_q2_meta%TYPE;
  v_valor_abs_neg_q3_meta  mi_metas_ooh.valor_abs_neg_q3_meta%TYPE;
  v_valor_abs_neg_q4_meta  mi_metas_ooh.valor_abs_neg_q4_meta%TYPE;
  v_data_q1_ini            DATE;
  v_data_q1_fim            DATE;
  v_data_q2_ini            DATE;
  v_data_q2_fim            DATE;
  v_data_q3_ini            DATE;
  v_data_q3_fim            DATE;
  v_data_q4_ini            DATE;
  v_data_q4_fim            DATE;
  v_flag_bonificacao       mi_metas_tv.flag_bonificacao%TYPE;
  --
  CURSOR c_pi IS
   SELECT DISTINCT ano,
                   veiculo,
                   praca,
                   formato
     FROM mi_pi pi
    WHERE empresa_id = p_empresa_id
      AND meio = 'OUT OF HOME'
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND NOT EXISTS (SELECT 1
             FROM mi_metas_ooh mt
            WHERE pi.empresa_id = mt.empresa_id
              AND pi.ano = mt.ano
              AND nvl(pi.veiculo, 'ZZZZZ') = nvl(mt.veiculo, 'ZZZZZ')
              AND nvl(pi.praca, 'ZZZZZ') = nvl(mt.praca, 'ZZZZZ')
              AND nvl(pi.formato, 'ZZZZZ') = nvl(mt.formato, 'ZZZZZ'));
  --
  CURSOR c_me IS
   SELECT mi_metas_ooh_id,
          veiculo,
          praca,
          formato,
          periodicidade,
          valor_unit_neg
     FROM mi_metas_ooh
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  v_data_q1_ini := data_converter('01/01/' || p_ano);
  v_data_q1_fim := data_converter('31/03/' || p_ano);
  --
  v_data_q2_ini := data_converter('01/04/' || p_ano);
  v_data_q2_fim := data_converter('30/06/' || p_ano);
  --
  v_data_q3_ini := data_converter('01/07/' || p_ano);
  v_data_q3_fim := data_converter('30/09/' || p_ano);
  --
  v_data_q4_ini := data_converter('01/10/' || p_ano);
  v_data_q4_fim := data_converter('31/12/' || p_ano);
  --
  ------------------------------------------------------------
  -- carga dos registros sem meta
  ------------------------------------------------------------
  DELETE FROM mi_metas_ooh
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano
     AND flag_sem_meta = 'S';
  --
  COMMIT;
  --
  FOR r_pi IN c_pi
  LOOP
   v_flag_bonificacao := 'N';
   --
   SELECT nvl(MAX(flag_bonificacao), 'N')
     INTO v_flag_bonificacao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_pi.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_pi.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_pi.formato, 'ZZZZZ');
   --
   INSERT INTO mi_metas_ooh
    (mi_metas_ooh_id,
     empresa_id,
     ano,
     data_carga,
     veiculo,
     praca,
     formato,
     periodicidade,
     flag_sem_meta,
     flag_bonificacao)
   VALUES
    (seq_mi_metas_ooh.nextval,
     p_empresa_id,
     r_pi.ano,
     SYSDATE,
     r_pi.veiculo,
     r_pi.praca,
     r_pi.formato,
     NULL,
     'S',
     v_flag_bonificacao);
  END LOOP;
  --
  COMMIT;
  --
  ------------------------------------------------------------
  -- calculo dos valores realizados
  ------------------------------------------------------------
  FOR r_me IN c_me
  LOOP
   --
   -- CALCULO DE VALOR_UNIT_NEG REALIZADO
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE PERC_NEGOC REALIZADO
   SELECT nvl(round(SUM(perc_negoc) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_perc_negoc_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   --
   SELECT nvl(round(SUM(perc_negoc) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_perc_negoc_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(perc_negoc) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_perc_negoc_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(perc_negoc) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_perc_negoc_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(perc_negoc) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_perc_negoc_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_REAL
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_META
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q1_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q2_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q3_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q4_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'OUT OF HOME'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   UPDATE mi_metas_ooh
      SET valor_unit_neg_real    = v_valor_unit_neg_real,
          valor_unit_neg_q1_real = v_valor_unit_neg_q1_real,
          valor_unit_neg_q2_real = v_valor_unit_neg_q2_real,
          valor_unit_neg_q3_real = v_valor_unit_neg_q3_real,
          valor_unit_neg_q4_real = v_valor_unit_neg_q4_real,
          perc_negoc_real        = v_perc_negoc_real,
          perc_negoc_q1_real     = v_perc_negoc_q1_real,
          perc_negoc_q2_real     = v_perc_negoc_q2_real,
          perc_negoc_q3_real     = v_perc_negoc_q3_real,
          perc_negoc_q4_real     = v_perc_negoc_q4_real,
          valor_abs_neg_q1_real  = v_valor_abs_neg_q1_real,
          valor_abs_neg_q2_real  = v_valor_abs_neg_q2_real,
          valor_abs_neg_q3_real  = v_valor_abs_neg_q3_real,
          valor_abs_neg_q4_real  = v_valor_abs_neg_q4_real,
          valor_abs_neg_q1_meta  = v_valor_abs_neg_q1_meta,
          valor_abs_neg_q2_meta  = v_valor_abs_neg_q2_meta,
          valor_abs_neg_q3_meta  = v_valor_abs_neg_q3_meta,
          valor_abs_neg_q4_meta  = v_valor_abs_neg_q4_meta
    WHERE mi_metas_ooh_id = r_me.mi_metas_ooh_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_ooh_calcular;
 --
 --
 PROCEDURE metas_radio_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/07/2019
  -- DESCRICAO: limpa tabela MI_METAS_RADIO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_ano       mi_metas_radio.ano%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_metas_radio
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_radio_limpar;
 --
 --
 PROCEDURE metas_radio_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2019
  -- DESCRICAO: carrega tabela MI_METAS_RADIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
  p_ano               IN VARCHAR2,
  p_veiculo           IN VARCHAR2,
  p_praca             IN VARCHAR2,
  p_formato           IN VARCHAR2,
  p_valor_unit_neg    IN VARCHAR2,
  p_daypart           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                INTEGER;
  v_ok                INTEGER;
  v_exception         EXCEPTION;
  v_mi_metas_radio_id mi_metas_radio.mi_metas_radio_id%TYPE;
  v_ano               mi_metas_radio.ano%TYPE;
  v_praca             mi_metas_radio.praca%TYPE;
  v_veiculo           mi_metas_radio.veiculo%TYPE;
  v_valor_unit_neg    mi_metas_radio.valor_unit_neg%TYPE;
  v_mi_daypart_id     mi_metas_radio.mi_daypart_id%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF length(TRIM(p_veiculo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VEICULO não pode ter mais que 100 caracteres (' || p_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_veiculo := TRIM(upper(acento_retirar(p_veiculo)));
  v_veiculo := TRIM(REPLACE(v_veiculo, '  ', ' '));
  --
  IF length(TRIM(p_praca)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA não pode ter mais que 100 caracteres (' || p_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_praca := upper(TRIM(REPLACE(p_praca, '  ', ' ')));
  --
  IF length(TRIM(p_formato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FORMATO não pode ter mais que 100 caracteres (' || p_formato || ').';
   RAISE v_exception;
  END IF;
  --
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_neg) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_NEG inválido (' || p_valor_unit_neg || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_neg := round(mi_carga_pkg.numero_converter(p_valor_unit_neg), 4);
  --
  IF length(TRIM(p_daypart)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo DAYPART não pode ter mais que 100 caracteres (' || p_daypart || ').';
   RAISE v_exception;
  END IF;
  --
  v_mi_daypart_id := daypart_id_retornar(p_empresa_id, p_daypart, NULL);
  --
  IF v_mi_daypart_id IS NULL THEN
   SELECT MAX(mi_daypart_id)
     INTO v_mi_daypart_id
     FROM mi_daypart
    WHERE empresa_id = p_empresa_id
      AND nome LIKE 'ND%';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_metas_radio.nextval
    INTO v_mi_metas_radio_id
    FROM dual;
  --
  INSERT INTO mi_metas_radio
   (mi_metas_radio_id,
    empresa_id,
    mi_carga_id,
    ano,
    data_carga,
    veiculo,
    praca,
    formato,
    valor_unit_neg,
    flag_sem_meta,
    daypart,
    mi_daypart_id)
  VALUES
   (v_mi_metas_radio_id,
    p_empresa_id,
    p_mi_carga_id,
    v_ano,
    SYSDATE,
    v_veiculo,
    v_praca,
    upper(TRIM(p_formato)),
    v_valor_unit_neg,
    'N',
    TRIM(p_daypart),
    v_mi_daypart_id);
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_radio_carregar;
 --
 --
 PROCEDURE metas_radio_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2019
  -- DESCRICAO: calcula demais campos da tabela MI_METAS_RADIO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                     INTEGER;
  v_ok                     INTEGER;
  v_exception              EXCEPTION;
  v_ano                    mi_metas_radio.ano%TYPE;
  v_valor_unit_neg_real    mi_metas_radio.valor_unit_neg_real%TYPE;
  v_mi_daypart_id          mi_metas_radio.mi_daypart_id%TYPE;
  v_valor_unit_neg_q1_real mi_metas_radio.valor_unit_neg_q1_real%TYPE;
  v_valor_unit_neg_q2_real mi_metas_radio.valor_unit_neg_q2_real%TYPE;
  v_valor_unit_neg_q3_real mi_metas_radio.valor_unit_neg_q3_real%TYPE;
  v_valor_unit_neg_q4_real mi_metas_radio.valor_unit_neg_q4_real%TYPE;
  v_valor_abs_neg_q1_real  mi_metas_radio.valor_abs_neg_q1_real%TYPE;
  v_valor_abs_neg_q2_real  mi_metas_radio.valor_abs_neg_q2_real%TYPE;
  v_valor_abs_neg_q3_real  mi_metas_radio.valor_abs_neg_q3_real%TYPE;
  v_valor_abs_neg_q4_real  mi_metas_radio.valor_abs_neg_q4_real%TYPE;
  v_valor_abs_neg_q1_meta  mi_metas_radio.valor_abs_neg_q1_meta%TYPE;
  v_valor_abs_neg_q2_meta  mi_metas_radio.valor_abs_neg_q2_meta%TYPE;
  v_valor_abs_neg_q3_meta  mi_metas_radio.valor_abs_neg_q3_meta%TYPE;
  v_valor_abs_neg_q4_meta  mi_metas_radio.valor_abs_neg_q4_meta%TYPE;
  v_data_q1_ini            DATE;
  v_data_q1_fim            DATE;
  v_data_q2_ini            DATE;
  v_data_q2_fim            DATE;
  v_data_q3_ini            DATE;
  v_data_q3_fim            DATE;
  v_data_q4_ini            DATE;
  v_data_q4_fim            DATE;
  v_flag_bonificacao       mi_metas_tv.flag_bonificacao%TYPE;
  --
  CURSOR c_pi IS
   SELECT DISTINCT ano,
                   veiculo,
                   praca,
                   formato
     FROM mi_pi pi
    WHERE empresa_id = p_empresa_id
      AND meio = 'RADIO'
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND NOT EXISTS (SELECT 1
             FROM mi_metas_radio mt
            WHERE pi.empresa_id = mt.empresa_id
              AND pi.ano = mt.ano
              AND nvl(pi.veiculo, 'ZZZZZ') = nvl(mt.veiculo, 'ZZZZZ')
              AND nvl(pi.praca, 'ZZZZZ') = nvl(mt.praca, 'ZZZZZ')
              AND nvl(pi.formato, 'ZZZZZ') = nvl(mt.formato, 'ZZZZZ'));
  --
  CURSOR c_me IS
   SELECT mi_metas_radio_id,
          veiculo,
          praca,
          formato,
          valor_unit_neg
     FROM mi_metas_radio
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  v_data_q1_ini := data_converter('01/01/' || p_ano);
  v_data_q1_fim := data_converter('31/03/' || p_ano);
  --
  v_data_q2_ini := data_converter('01/04/' || p_ano);
  v_data_q2_fim := data_converter('30/06/' || p_ano);
  --
  v_data_q3_ini := data_converter('01/07/' || p_ano);
  v_data_q3_fim := data_converter('30/09/' || p_ano);
  --
  v_data_q4_ini := data_converter('01/10/' || p_ano);
  v_data_q4_fim := data_converter('31/12/' || p_ano);
  --
  ------------------------------------------------------------
  -- carga dos registros sem meta
  ------------------------------------------------------------
  --
  -- carrega com daypart padrao
  v_mi_daypart_id := daypart_id_retornar(p_empresa_id, '06h-19h', NULL);
  --
  IF v_mi_daypart_id IS NULL THEN
   SELECT MAX(mi_daypart_id)
     INTO v_mi_daypart_id
     FROM mi_daypart
    WHERE empresa_id = p_empresa_id
      AND nome LIKE 'ND%';
  END IF;
  --
  DELETE FROM mi_metas_radio
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano
     AND flag_sem_meta = 'S';
  --
  COMMIT;
  --
  FOR r_pi IN c_pi
  LOOP
   v_flag_bonificacao := 'N';
   --
   SELECT nvl(MAX(flag_bonificacao), 'N')
     INTO v_flag_bonificacao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_pi.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_pi.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_pi.formato, 'ZZZZZ');
   --
   INSERT INTO mi_metas_radio
    (mi_metas_radio_id,
     empresa_id,
     ano,
     data_carga,
     veiculo,
     praca,
     formato,
     flag_sem_meta,
     mi_daypart_id,
     flag_bonificacao)
   VALUES
    (seq_mi_metas_radio.nextval,
     p_empresa_id,
     r_pi.ano,
     SYSDATE,
     r_pi.veiculo,
     r_pi.praca,
     r_pi.formato,
     'S',
     v_mi_daypart_id,
     v_flag_bonificacao);
  END LOOP;
  --
  COMMIT;
  --
  ------------------------------------------------------------
  -- calculo dos valores realizados
  ------------------------------------------------------------
  FOR r_me IN c_me
  LOOP
   --
   -- CALCULO DE VALOR_UNIT_NEG REALIZADO
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_REAL
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_META
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q1_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q2_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q3_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q4_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'RADIO'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   UPDATE mi_metas_radio
      SET valor_unit_neg_real    = v_valor_unit_neg_real,
          valor_unit_neg_q1_real = v_valor_unit_neg_q1_real,
          valor_unit_neg_q2_real = v_valor_unit_neg_q2_real,
          valor_unit_neg_q3_real = v_valor_unit_neg_q3_real,
          valor_unit_neg_q4_real = v_valor_unit_neg_q4_real,
          valor_abs_neg_q1_real  = v_valor_abs_neg_q1_real,
          valor_abs_neg_q2_real  = v_valor_abs_neg_q2_real,
          valor_abs_neg_q3_real  = v_valor_abs_neg_q3_real,
          valor_abs_neg_q4_real  = v_valor_abs_neg_q4_real,
          valor_abs_neg_q1_meta  = v_valor_abs_neg_q1_meta,
          valor_abs_neg_q2_meta  = v_valor_abs_neg_q2_meta,
          valor_abs_neg_q3_meta  = v_valor_abs_neg_q3_meta,
          valor_abs_neg_q4_meta  = v_valor_abs_neg_q4_meta
    WHERE mi_metas_radio_id = r_me.mi_metas_radio_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_radio_calcular;
 --
 --
 PROCEDURE metas_print_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/07/2019
  -- DESCRICAO: limpa tabela MI_METAS_PRINT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_ano       mi_metas_print.ano%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_metas_print
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_print_limpar;
 --
 --
 PROCEDURE metas_print_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2019
  -- DESCRICAO: carrega tabela MI_METAS_PRINT
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
  p_ano               IN VARCHAR2,
  p_veiculo           IN VARCHAR2,
  p_praca             IN VARCHAR2,
  p_formato           IN VARCHAR2,
  p_valor_unit_neg    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                INTEGER;
  v_ok                INTEGER;
  v_exception         EXCEPTION;
  v_mi_metas_print_id mi_metas_print.mi_metas_print_id%TYPE;
  v_ano               mi_metas_print.ano%TYPE;
  v_praca             mi_metas_print.praca%TYPE;
  v_veiculo           mi_metas_print.veiculo%TYPE;
  v_valor_unit_neg    mi_metas_print.valor_unit_neg%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF length(TRIM(p_veiculo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VEICULO não pode ter mais que 100 caracteres (' || p_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_veiculo := TRIM(upper(acento_retirar(p_veiculo)));
  v_veiculo := TRIM(REPLACE(v_veiculo, '  ', ' '));
  --
  IF length(TRIM(p_praca)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA não pode ter mais que 100 caracteres (' || p_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_praca := upper(TRIM(REPLACE(p_praca, '  ', ' ')));
  --
  IF length(TRIM(p_formato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FORMATO não pode ter mais que 100 caracteres (' || p_formato || ').';
   RAISE v_exception;
  END IF;
  --
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_neg) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_NEG inválido (' || p_valor_unit_neg || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_neg := round(mi_carga_pkg.numero_converter(p_valor_unit_neg), 4);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_metas_print.nextval
    INTO v_mi_metas_print_id
    FROM dual;
  --
  INSERT INTO mi_metas_print
   (mi_metas_print_id,
    empresa_id,
    mi_carga_id,
    ano,
    data_carga,
    veiculo,
    praca,
    formato,
    valor_unit_neg,
    flag_sem_meta)
  VALUES
   (v_mi_metas_print_id,
    p_empresa_id,
    p_mi_carga_id,
    v_ano,
    SYSDATE,
    v_veiculo,
    v_praca,
    upper(TRIM(p_formato)),
    v_valor_unit_neg,
    'N');
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_print_carregar;
 --
 --
 PROCEDURE metas_print_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2019
  -- DESCRICAO: calcula demais campos da tabela MI_METAS_PRINT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                     INTEGER;
  v_ok                     INTEGER;
  v_exception              EXCEPTION;
  v_ano                    mi_metas_print.ano%TYPE;
  v_valor_unit_neg_real    mi_metas_print.valor_unit_neg_real%TYPE;
  v_valor_unit_neg_q1_real mi_metas_print.valor_unit_neg_q1_real%TYPE;
  v_valor_unit_neg_q2_real mi_metas_print.valor_unit_neg_q2_real%TYPE;
  v_valor_unit_neg_q3_real mi_metas_print.valor_unit_neg_q3_real%TYPE;
  v_valor_unit_neg_q4_real mi_metas_print.valor_unit_neg_q4_real%TYPE;
  v_valor_abs_neg_q1_real  mi_metas_print.valor_abs_neg_q1_real%TYPE;
  v_valor_abs_neg_q2_real  mi_metas_print.valor_abs_neg_q2_real%TYPE;
  v_valor_abs_neg_q3_real  mi_metas_print.valor_abs_neg_q3_real%TYPE;
  v_valor_abs_neg_q4_real  mi_metas_print.valor_abs_neg_q4_real%TYPE;
  v_valor_abs_neg_q1_meta  mi_metas_print.valor_abs_neg_q1_meta%TYPE;
  v_valor_abs_neg_q2_meta  mi_metas_print.valor_abs_neg_q2_meta%TYPE;
  v_valor_abs_neg_q3_meta  mi_metas_print.valor_abs_neg_q3_meta%TYPE;
  v_valor_abs_neg_q4_meta  mi_metas_print.valor_abs_neg_q4_meta%TYPE;
  v_data_q1_ini            DATE;
  v_data_q1_fim            DATE;
  v_data_q2_ini            DATE;
  v_data_q2_fim            DATE;
  v_data_q3_ini            DATE;
  v_data_q3_fim            DATE;
  v_data_q4_ini            DATE;
  v_data_q4_fim            DATE;
  v_flag_bonificacao       mi_metas_tv.flag_bonificacao%TYPE;
  --
  CURSOR c_pi IS
   SELECT DISTINCT ano,
                   veiculo,
                   praca,
                   formato
     FROM mi_pi pi
    WHERE empresa_id = p_empresa_id
      AND meio IN ('JORNAL', 'REVISTA')
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND NOT EXISTS (SELECT 1
             FROM mi_metas_print mt
            WHERE pi.empresa_id = mt.empresa_id
              AND pi.ano = mt.ano
              AND nvl(pi.veiculo, 'ZZZZZ') = nvl(mt.veiculo, 'ZZZZZ')
              AND nvl(pi.praca, 'ZZZZZ') = nvl(mt.praca, 'ZZZZZ')
              AND nvl(pi.formato, 'ZZZZZ') = nvl(mt.formato, 'ZZZZZ'));
  --
  CURSOR c_me IS
   SELECT mi_metas_print_id,
          veiculo,
          praca,
          formato,
          valor_unit_neg
     FROM mi_metas_print
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  v_data_q1_ini := data_converter('01/01/' || p_ano);
  v_data_q1_fim := data_converter('31/03/' || p_ano);
  --
  v_data_q2_ini := data_converter('01/04/' || p_ano);
  v_data_q2_fim := data_converter('30/06/' || p_ano);
  --
  v_data_q3_ini := data_converter('01/07/' || p_ano);
  v_data_q3_fim := data_converter('30/09/' || p_ano);
  --
  v_data_q4_ini := data_converter('01/10/' || p_ano);
  v_data_q4_fim := data_converter('31/12/' || p_ano);
  --
  ------------------------------------------------------------
  -- carga dos registros sem meta
  ------------------------------------------------------------
  --
  DELETE FROM mi_metas_print
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano
     AND flag_sem_meta = 'S';
  --
  COMMIT;
  --
  FOR r_pi IN c_pi
  LOOP
   v_flag_bonificacao := 'N';
   --
   SELECT nvl(MAX(flag_bonificacao), 'N')
     INTO v_flag_bonificacao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_pi.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_pi.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_pi.formato, 'ZZZZZ');
   --
   INSERT INTO mi_metas_print
    (mi_metas_print_id,
     empresa_id,
     ano,
     data_carga,
     veiculo,
     praca,
     formato,
     flag_sem_meta,
     flag_bonificacao)
   VALUES
    (seq_mi_metas_print.nextval,
     p_empresa_id,
     r_pi.ano,
     SYSDATE,
     r_pi.veiculo,
     r_pi.praca,
     r_pi.formato,
     'S',
     v_flag_bonificacao);
  END LOOP;
  --
  COMMIT;
  --
  ------------------------------------------------------------
  -- calculo dos valores realizados
  ------------------------------------------------------------
  FOR r_me IN c_me
  LOOP
   --
   -- CALCULO DE VALOR_UNIT_NEG REALIZADO
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) / zvl(COUNT(*), NULL), 4), 0)
     INTO v_valor_unit_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_REAL
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8, 4), 0)
     INTO v_valor_abs_neg_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_ABS_NEG_META
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q1_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q2_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q3_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(COUNT(*) * r_me.valor_unit_neg, 4), 0)
     INTO v_valor_abs_neg_q4_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio IN ('JORNAL', 'REVISTA')
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   UPDATE mi_metas_print
      SET valor_unit_neg_real    = v_valor_unit_neg_real,
          valor_unit_neg_q1_real = v_valor_unit_neg_q1_real,
          valor_unit_neg_q2_real = v_valor_unit_neg_q2_real,
          valor_unit_neg_q3_real = v_valor_unit_neg_q3_real,
          valor_unit_neg_q4_real = v_valor_unit_neg_q4_real,
          valor_abs_neg_q1_real  = v_valor_abs_neg_q1_real,
          valor_abs_neg_q2_real  = v_valor_abs_neg_q2_real,
          valor_abs_neg_q3_real  = v_valor_abs_neg_q3_real,
          valor_abs_neg_q4_real  = v_valor_abs_neg_q4_real,
          valor_abs_neg_q1_meta  = v_valor_abs_neg_q1_meta,
          valor_abs_neg_q2_meta  = v_valor_abs_neg_q2_meta,
          valor_abs_neg_q3_meta  = v_valor_abs_neg_q3_meta,
          valor_abs_neg_q4_meta  = v_valor_abs_neg_q4_meta
    WHERE mi_metas_print_id = r_me.mi_metas_print_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_print_calcular;
 --
 --
 PROCEDURE metas_digital_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/07/2019
  -- DESCRICAO: limpa tabela MI_METAS_DIGITAL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_ano       mi_metas_digital.ano%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_metas_digital
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_digital_limpar;
 --
 --
 PROCEDURE metas_digital_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/07/2019
  -- DESCRICAO: carrega tabela MI_METAS_DIGITAL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
  p_ano               IN VARCHAR2,
  p_veiculo           IN VARCHAR2,
  p_formato           IN VARCHAR2,
  p_negociacao        IN VARCHAR2,
  p_valor_unit_neg    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                  INTEGER;
  v_ok                  INTEGER;
  v_exception           EXCEPTION;
  v_mi_metas_digital_id mi_metas_digital.mi_metas_digital_id%TYPE;
  v_ano                 mi_metas_digital.ano%TYPE;
  v_negociacao          mi_metas_digital.negociacao%TYPE;
  v_veiculo             mi_metas_digital.veiculo%TYPE;
  v_valor_unit_neg      mi_metas_digital.valor_unit_neg%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF length(TRIM(p_veiculo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VEICULO não pode ter mais que 100 caracteres (' || p_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_veiculo := TRIM(upper(acento_retirar(p_veiculo)));
  v_veiculo := TRIM(REPLACE(v_veiculo, '  ', ' '));
  --
  IF length(TRIM(p_negociacao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA não pode ter mais que 100 caracteres (' || p_negociacao || ').';
   RAISE v_exception;
  END IF;
  --
  v_negociacao := upper(TRIM(REPLACE(p_negociacao, '  ', ' ')));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPM BUYS', 'CPM'));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPD (COST/DOWNLOAD)', 'CPD'));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPL (COST/LEAD)', 'CPL'));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPD (COST/DAY)', 'CPD'));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPE BUYS', 'CPE'));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPD (COST/DAY) BUYS', 'CPD'));
  --
  IF length(TRIM(p_formato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FORMATO não pode ter mais que 100 caracteres (' || p_formato || ').';
   RAISE v_exception;
  END IF;
  --
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_neg) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_NEG inválido (' || p_valor_unit_neg || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_neg := round(mi_carga_pkg.numero_converter(p_valor_unit_neg), 4);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_metas_digital.nextval
    INTO v_mi_metas_digital_id
    FROM dual;
  --
  INSERT INTO mi_metas_digital
   (mi_metas_digital_id,
    empresa_id,
    mi_carga_id,
    ano,
    data_carga,
    veiculo,
    negociacao,
    formato,
    valor_unit_neg,
    flag_sem_meta)
  VALUES
   (v_mi_metas_digital_id,
    p_empresa_id,
    p_mi_carga_id,
    v_ano,
    SYSDATE,
    v_veiculo,
    v_negociacao,
    upper(TRIM(p_formato)),
    v_valor_unit_neg,
    'N');
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_digital_carregar;
 --
 --
 PROCEDURE metas_digital_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/07/2019
  -- DESCRICAO: calcula demais campos da tabela MI_METAS_DIGITAL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                     INTEGER;
  v_ok                     INTEGER;
  v_exception              EXCEPTION;
  v_ano                    mi_metas_digital.ano%TYPE;
  v_valor_unit_neg_real    mi_metas_digital.valor_unit_neg_real%TYPE;
  v_valor_unit_neg_q1_real mi_metas_digital.valor_unit_neg_q1_real%TYPE;
  v_valor_unit_neg_q2_real mi_metas_digital.valor_unit_neg_q2_real%TYPE;
  v_valor_unit_neg_q3_real mi_metas_digital.valor_unit_neg_q3_real%TYPE;
  v_valor_unit_neg_q4_real mi_metas_digital.valor_unit_neg_q4_real%TYPE;
  v_valor_unit_neg_q1_med  mi_metas_digital.valor_unit_neg_q1_med%TYPE;
  v_valor_unit_neg_q2_med  mi_metas_digital.valor_unit_neg_q2_med%TYPE;
  v_valor_unit_neg_q3_med  mi_metas_digital.valor_unit_neg_q3_med%TYPE;
  v_valor_unit_neg_q4_med  mi_metas_digital.valor_unit_neg_q4_med%TYPE;
  v_valor_unit_neg_q1      mi_metas_digital.valor_unit_neg_q1%TYPE;
  v_valor_unit_neg_q2      mi_metas_digital.valor_unit_neg_q2%TYPE;
  v_valor_unit_neg_q3      mi_metas_digital.valor_unit_neg_q3%TYPE;
  v_valor_unit_neg_q4      mi_metas_digital.valor_unit_neg_q4%TYPE;
  v_data_q1_ini            DATE;
  v_data_q1_fim            DATE;
  v_data_q2_ini            DATE;
  v_data_q2_fim            DATE;
  v_data_q3_ini            DATE;
  v_data_q3_fim            DATE;
  v_data_q4_ini            DATE;
  v_data_q4_fim            DATE;
  v_flag_bonificacao       mi_metas_tv.flag_bonificacao%TYPE;
  --
  CURSOR c_pi IS
   SELECT DISTINCT ano,
                   veiculo,
                   negociacao,
                   formato
     FROM mi_pi pi
    WHERE empresa_id = p_empresa_id
      AND meio = 'INTERNET'
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND NOT EXISTS (SELECT 1
             FROM mi_metas_digital mt
            WHERE pi.empresa_id = mt.empresa_id
              AND pi.ano = mt.ano
              AND nvl(pi.veiculo, 'ZZZZZ') = nvl(mt.veiculo, 'ZZZZZ')
              AND nvl(pi.negociacao, 'ZZZZZ') = nvl(mt.negociacao, 'ZZZZZ')
              AND nvl(pi.formato, 'ZZZZZ') = nvl(mt.formato, 'ZZZZZ'));
  --
  CURSOR c_me IS
   SELECT mi_metas_digital_id,
          veiculo,
          negociacao,
          formato,
          valor_unit_neg
     FROM mi_metas_digital
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  v_data_q1_ini := data_converter('01/01/' || p_ano);
  v_data_q1_fim := data_converter('31/03/' || p_ano);
  --
  v_data_q2_ini := data_converter('01/04/' || p_ano);
  v_data_q2_fim := data_converter('30/06/' || p_ano);
  --
  v_data_q3_ini := data_converter('01/07/' || p_ano);
  v_data_q3_fim := data_converter('30/09/' || p_ano);
  --
  v_data_q4_ini := data_converter('01/10/' || p_ano);
  v_data_q4_fim := data_converter('31/12/' || p_ano);
  --
  ------------------------------------------------------------
  -- carga dos registros sem meta
  ------------------------------------------------------------
  --
  DELETE FROM mi_metas_digital
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano
     AND flag_sem_meta = 'S';
  --
  COMMIT;
  --
  FOR r_pi IN c_pi
  LOOP
   v_flag_bonificacao := 'N';
   --
   SELECT nvl(MAX(flag_bonificacao), 'N')
     INTO v_flag_bonificacao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'INTERNET'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_pi.veiculo, 'ZZZZZ')
      AND nvl(negociacao, 'ZZZZZ') = nvl(r_pi.negociacao, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_pi.formato, 'ZZZZZ');
   --
   INSERT INTO mi_metas_digital
    (mi_metas_digital_id,
     empresa_id,
     ano,
     data_carga,
     veiculo,
     negociacao,
     formato,
     flag_sem_meta,
     flag_bonificacao)
   VALUES
    (seq_mi_metas_digital.nextval,
     p_empresa_id,
     r_pi.ano,
     SYSDATE,
     r_pi.veiculo,
     r_pi.negociacao,
     r_pi.formato,
     'S',
     v_flag_bonificacao);
  END LOOP;
  --
  COMMIT;
  --
  ------------------------------------------------------------
  -- calculo dos valores realizados
  ------------------------------------------------------------
  FOR r_me IN c_me
  LOOP
   /*
    --
    -- CALCULO DE VALOR_UNIT_NEG REALIZADO - GERAL
    IF r_me.negociacao IN ('CPC','CPD','CPV','CPVT') THEN
       SELECT NVL(SUM(ROUND(valor_unit_neg / ZVL(tot_ins,NULL),4)),0)
         INTO v_valor_unit_neg_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND NVL(veiculo,'ZZZZZ') = NVL(r_me.veiculo,'ZZZZZ')
          AND NVL(negociacao,'ZZZZZ') = NVL(r_me.negociacao,'ZZZZZ')
          AND NVL(formato,'ZZZZZ') = NVL(r_me.formato,'ZZZZZ');
    ELSIF r_me.negociacao IN ('CPM') THEN
       SELECT NVL(SUM(ROUND(valor_unit_tab*qtd_impressoes/1000,4)),0)
         INTO v_valor_unit_neg_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND NVL(veiculo,'ZZZZZ') = NVL(r_me.veiculo,'ZZZZZ')
          AND NVL(negociacao,'ZZZZZ') = NVL(r_me.negociacao,'ZZZZZ')
          AND NVL(formato,'ZZZZZ') = NVL(r_me.formato,'ZZZZZ');
    ELSIF r_me.negociacao IN ('CUSTO FIXO','CUSTO FIXO IMP','DIÁRIA','MENSAL','PATROCINIO') THEN
       SELECT NVL(ROUND(SUM(valor_total),4),0)
         INTO v_valor_unit_neg_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND NVL(veiculo,'ZZZZZ') = NVL(r_me.veiculo,'ZZZZZ')
          AND NVL(negociacao,'ZZZZZ') = NVL(r_me.negociacao,'ZZZZZ')
          AND NVL(formato,'ZZZZZ') = NVL(r_me.formato,'ZZZZZ');
    END IF;
   */
   --
   -- CALCULO DE VALOR_UNIT_NEG REALIZADO - GERAL
   -- alterado em 08/11/2021 para ficae igyal ao quarter
   IF r_me.negociacao IN ('CPM') THEN
    SELECT nvl((SUM(qtd_impressoes) *
               ((SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1) * 1000) / 1000) * 0.8),
               0)
      INTO v_valor_unit_neg_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   ELSE
    SELECT nvl((SUM(qtd_impressoes) * (SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1)) * 0.8),
               0)
      INTO v_valor_unit_neg_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ');
   END IF;
   --
   -- CALCULO DE VALOR_UNIT_NEG REALIZADO - POR QUARTER
   IF r_me.negociacao IN ('CPM') THEN
    --SELECT NVL(SUM(ROUND(qtd_impressoes*valor_unit_tab*(1-perc_negoc/100)/1000,4)),0)
    -- alterado em 13/01/2021
    -- com esse novo calculo (que soma primeiro e depois faz a conta), os valores agrupados
    -- por veiculo/negociacao/formato nao vao bater com o total geral sem agrupamento.
    SELECT nvl((SUM(qtd_impressoes) *
               ((SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1) * 1000) / 1000) * 0.8),
               0)
      INTO v_valor_unit_neg_q1_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) *
               ((SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1) * 1000) / 1000) * 0.8),
               0)
      INTO v_valor_unit_neg_q2_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) *
               ((SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1) * 1000) / 1000) * 0.8),
               0)
      INTO v_valor_unit_neg_q3_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) *
               ((SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1) * 1000) / 1000) * 0.8),
               0)
      INTO v_valor_unit_neg_q4_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   ELSE
    -- IF r_me.negociacao IN ('CPC','CPD','CPV','CPVT') THEN
    -- SELECT NVL(SUM(ROUND(qtd_impressoes*valor_unit_tab*(1-perc_negoc/100),4)),0)
    -- alterado em 13/01/2021
    SELECT nvl((SUM(qtd_impressoes) * (SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1)) * 0.8),
               0)
      INTO v_valor_unit_neg_q1_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) * (SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1)) * 0.8),
               0)
      INTO v_valor_unit_neg_q2_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) * (SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1)) * 0.8),
               0)
      INTO v_valor_unit_neg_q3_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
    --
    SELECT nvl((SUM(qtd_impressoes) * (SUM(valor_unit_neg) / zvl(SUM(qtd_impressoes), 1)) * 0.8),
               0)
      INTO v_valor_unit_neg_q4_real
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
    /*
    ELSIF r_me.negociacao IN ('CUSTO FIXO','CUSTO FIXO IMP','DIÁRIA','MENSAL','PATROCINIO') THEN
       SELECT NVL(ROUND(SUM(valor_total),4),0)
         INTO v_valor_unit_neg_q1_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND veiculo = r_me.veiculo
          AND negociacao = r_me.negociacao
          AND formato = r_me.formato
          AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
       --
       SELECT NVL(ROUND(SUM(valor_total),4),0)
         INTO v_valor_unit_neg_q2_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND veiculo = r_me.veiculo
          AND negociacao = r_me.negociacao
          AND formato = r_me.formato
          AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
       --
       SELECT NVL(ROUND(SUM(valor_total),4),0)
         INTO v_valor_unit_neg_q3_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND veiculo = r_me.veiculo
          AND negociacao = r_me.negociacao
          AND formato = r_me.formato
          AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
       --
       SELECT NVL(ROUND(SUM(valor_total),4),0)
         INTO v_valor_unit_neg_q4_real
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'INTERNET'
          AND veiculo = r_me.veiculo
          AND negociacao = r_me.negociacao
          AND formato = r_me.formato
          AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim; */
   END IF;
   --
   -- -- CALCULO DE VALOR_UNIT_NEG MEDIO - POR QUARTER
   --SELECT NVL(ROUND(SUM(valor_unit_neg) / ZVL(COUNT(*),NULL),4),0)
   SELECT nvl(round((SUM(valor_unit_neg) / zvl(COUNT(*), NULL)) * 0.8 /
                    zvl(SUM(tot_ins), NULL),
                    4),
              0)
     INTO v_valor_unit_neg_q1_med
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'INTERNET'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   --SELECT NVL(ROUND(SUM(valor_unit_neg) / ZVL(COUNT(*),NULL),4),0)
   SELECT nvl(round((SUM(valor_unit_neg) / zvl(COUNT(*), NULL)) * 0.8 /
                    zvl(SUM(tot_ins), NULL),
                    4),
              0)
     INTO v_valor_unit_neg_q2_med
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'INTERNET'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   --SELECT NVL(ROUND(SUM(valor_unit_neg) / ZVL(COUNT(*),NULL),4),0)
   SELECT nvl(round((SUM(valor_unit_neg) / zvl(COUNT(*), NULL)) * 0.8 /
                    zvl(SUM(tot_ins), NULL),
                    4),
              0)
     INTO v_valor_unit_neg_q3_med
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'INTERNET'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   --SELECT NVL(ROUND(SUM(valor_unit_neg) / ZVL(COUNT(*),NULL),4),0)
   SELECT nvl(round((SUM(valor_unit_neg) / zvl(COUNT(*), NULL)) * 0.8 /
                    zvl(SUM(tot_ins), NULL),
                    4),
              0)
     INTO v_valor_unit_neg_q4_med
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'INTERNET'
      AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
      AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
      AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR_UNIT_NEG - POR QUARTER
   IF r_me.negociacao IN ('CPM') THEN
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes / 1000, 4)), 0)
      INTO v_valor_unit_neg_q1
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes / 1000, 4)), 0)
      INTO v_valor_unit_neg_q2
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes / 1000, 4)), 0)
      INTO v_valor_unit_neg_q3
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes / 1000, 4)), 0)
      INTO v_valor_unit_neg_q4
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   ELSE
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes, 4)), 0)
      INTO v_valor_unit_neg_q1
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes, 4)), 0)
      INTO v_valor_unit_neg_q2
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes, 4)), 0)
      INTO v_valor_unit_neg_q3
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
    --
    SELECT nvl(SUM(round(r_me.valor_unit_neg * qtd_impressoes, 4)), 0)
      INTO v_valor_unit_neg_q4
      FROM mi_pi
     WHERE empresa_id = p_empresa_id
       AND flag_descartar = 'N'
       AND ano = v_ano
       AND meio = 'INTERNET'
       AND nvl(veiculo, 'ZZZZZ') = nvl(r_me.veiculo, 'ZZZZZ')
       AND nvl(negociacao, 'ZZZZZ') = nvl(r_me.negociacao, 'ZZZZZ')
       AND nvl(formato, 'ZZZZZ') = nvl(r_me.formato, 'ZZZZZ')
       AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   END IF;
   --
   UPDATE mi_metas_digital
      SET valor_unit_neg_real    = v_valor_unit_neg_real,
          valor_unit_neg_q1_real = v_valor_unit_neg_q1_real,
          valor_unit_neg_q2_real = v_valor_unit_neg_q2_real,
          valor_unit_neg_q3_real = v_valor_unit_neg_q3_real,
          valor_unit_neg_q4_real = v_valor_unit_neg_q4_real,
          valor_unit_neg_q1_med  = v_valor_unit_neg_q1_med,
          valor_unit_neg_q2_med  = v_valor_unit_neg_q2_med,
          valor_unit_neg_q3_med  = v_valor_unit_neg_q3_med,
          valor_unit_neg_q4_med  = v_valor_unit_neg_q4_med,
          valor_unit_neg_q1      = v_valor_unit_neg_q1,
          valor_unit_neg_q2      = v_valor_unit_neg_q2,
          valor_unit_neg_q3      = v_valor_unit_neg_q3,
          valor_unit_neg_q4      = v_valor_unit_neg_q4
    WHERE mi_metas_digital_id = r_me.mi_metas_digital_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_digital_calcular;
 --
 --
 PROCEDURE metas_tv_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 10/06/2019
  -- DESCRICAO: limpa tabela MI_METAS_TV.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_ano       mi_metas_tv.ano%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_metas_tv
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_tv_limpar;
 --
 --
 PROCEDURE metas_tv_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 18/06/2019
  -- DESCRICAO: calcula demais campos da tabela MI_METAS_TV.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt                         INTEGER;
  v_ok                         INTEGER;
  v_exception                  EXCEPTION;
  v_ano                        mi_metas_tv.ano%TYPE;
  v_cpp_q1_real                mi_metas_tv.cpp_q1_real%TYPE;
  v_cpp_q2_real                mi_metas_tv.cpp_q2_real%TYPE;
  v_cpp_q3_real                mi_metas_tv.cpp_q3_real%TYPE;
  v_cpp_q4_real                mi_metas_tv.cpp_q4_real%TYPE;
  v_meio_compl                 mi_metas_tv.meio_compl%TYPE;
  v_data_q1_ini                DATE;
  v_data_q1_fim                DATE;
  v_data_q2_ini                DATE;
  v_data_q2_fim                DATE;
  v_data_q3_ini                DATE;
  v_data_q3_fim                DATE;
  v_data_q4_ini                DATE;
  v_data_q4_fim                DATE;
  v_cpp_sem_pond_q1_real       mi_metas_tv.cpp_sem_pond_q1_real%TYPE;
  v_cpp_sem_pond_q2_real       mi_metas_tv.cpp_sem_pond_q2_real%TYPE;
  v_cpp_sem_pond_q3_real       mi_metas_tv.cpp_sem_pond_q3_real%TYPE;
  v_cpp_sem_pond_q4_real       mi_metas_tv.cpp_sem_pond_q4_real%TYPE;
  v_valor_abs_q1_real          mi_metas_tv.valor_abs_q1_real%TYPE;
  v_valor_abs_q2_real          mi_metas_tv.valor_abs_q2_real%TYPE;
  v_valor_abs_q3_real          mi_metas_tv.valor_abs_q3_real%TYPE;
  v_valor_abs_q4_real          mi_metas_tv.valor_abs_q4_real%TYPE;
  v_valor_abs_q1_meta          mi_metas_tv.valor_abs_q1_meta%TYPE;
  v_valor_abs_q2_meta          mi_metas_tv.valor_abs_q2_meta%TYPE;
  v_valor_abs_q3_meta          mi_metas_tv.valor_abs_q3_meta%TYPE;
  v_valor_abs_q4_meta          mi_metas_tv.valor_abs_q4_meta%TYPE;
  v_valor_abs_sem_pond_q1_meta mi_metas_tv.valor_abs_sem_pond_q1_meta%TYPE;
  v_valor_abs_sem_pond_q2_meta mi_metas_tv.valor_abs_sem_pond_q2_meta%TYPE;
  v_valor_abs_sem_pond_q3_meta mi_metas_tv.valor_abs_sem_pond_q3_meta%TYPE;
  v_valor_abs_sem_pond_q4_meta mi_metas_tv.valor_abs_sem_pond_q4_meta%TYPE;
  v_aud_targ_q1                mi_metas_tv.aud_targ_q1%TYPE;
  v_aud_targ_q2                mi_metas_tv.aud_targ_q2%TYPE;
  v_aud_targ_q3                mi_metas_tv.aud_targ_q3%TYPE;
  v_aud_targ_q4                mi_metas_tv.aud_targ_q4%TYPE;
  v_flag_bonificacao           mi_metas_tv.flag_bonificacao%TYPE;
  v_descricao                  mi_pi.descricao%TYPE;
  --
  CURSOR c_pi IS
   SELECT DISTINCT mi_daypart_id,
                   ano,
                   meio,
                   target,
                   rede,
                   praca
     FROM mi_pi pi
    WHERE empresa_id = p_empresa_id
      AND meio = 'TELEVISÃO'
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND NOT EXISTS (SELECT 1
             FROM mi_metas_tv mt
            WHERE pi.empresa_id = mt.empresa_id
              AND pi.ano = mt.ano
              AND pi.meio = mt.meio
              AND nvl(pi.target, 'ZZZZZ') = nvl(mt.target, 'ZZZZZ')
              AND nvl(pi.rede, 'ZZZZZ') = nvl(mt.rede, 'ZZZZZ')
              AND nvl(pi.praca, 'ZZZZZ') = nvl(mt.praca, 'ZZZZZ')
              AND pi.mi_daypart_id = mt.mi_daypart_id);
  --
  CURSOR c_me IS
   SELECT mi_metas_tv_id,
          meio,
          target,
          rede,
          praca,
          mi_daypart_id,
          cpp_q1,
          cpp_q2,
          cpp_q3,
          cpp_q4
     FROM mi_metas_tv
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  v_data_q1_ini := data_converter('01/01/' || p_ano);
  v_data_q1_fim := data_converter('31/03/' || p_ano);
  --
  v_data_q2_ini := data_converter('01/04/' || p_ano);
  v_data_q2_fim := data_converter('30/06/' || p_ano);
  --
  v_data_q3_ini := data_converter('01/07/' || p_ano);
  v_data_q3_fim := data_converter('30/09/' || p_ano);
  --
  v_data_q4_ini := data_converter('01/10/' || p_ano);
  v_data_q4_fim := data_converter('31/12/' || p_ano);
  --
  ------------------------------------------------------------
  -- carga dos registros sem meta
  ------------------------------------------------------------
  DELETE FROM mi_metas_tv
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano
     AND flag_sem_meta = 'S';
  --
  COMMIT;
  --
  FOR r_pi IN c_pi
  LOOP
   v_flag_bonificacao := 'N';
   --
   SELECT nvl(MAX(flag_bonificacao), 'N')
     INTO v_flag_bonificacao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_pi.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_pi.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_pi.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_pi.praca, 'ZZZZZ')
      AND mi_daypart_id = r_pi.mi_daypart_id;
   --
   v_meio_compl := 'OTV RegBuy';
   --
   SELECT MAX(descricao)
     INTO v_descricao
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = r_pi.ano
      AND mi_daypart_id = r_pi.mi_daypart_id
      AND meio = r_pi.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_pi.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_pi.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_pi.praca, 'ZZZZZ');
   --
   IF v_descricao LIKE 'FUTEBOL%' THEN
    v_meio_compl := 'OTV Pckg';
   END IF;
   --
   IF r_pi.target LIKE '%PAY TV%' THEN
    v_meio_compl := 'Cable RegBuy';
   END IF;
   --
   INSERT INTO mi_metas_tv
    (mi_metas_tv_id,
     empresa_id,
     mi_daypart_id,
     ano,
     data_carga,
     meio,
     target,
     rede,
     praca,
     meio_compl,
     flag_sem_meta,
     flag_bonificacao)
   VALUES
    (seq_mi_metas_tv.nextval,
     p_empresa_id,
     r_pi.mi_daypart_id,
     r_pi.ano,
     SYSDATE,
     r_pi.meio,
     r_pi.target,
     r_pi.rede,
     r_pi.praca,
     v_meio_compl,
     'S',
     v_flag_bonificacao);
  END LOOP;
  --
  COMMIT;
  --
  ------------------------------------------------------------
  -- calculo dos valores realizados
  ------------------------------------------------------------
  FOR r_me IN c_me
  LOOP
   --
   -- CALCULO DE CPP REALIZADO
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(audiencia_pond), NULL), 4), 0)
     INTO v_cpp_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(audiencia_pond), NULL), 4), 0)
     INTO v_cpp_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(audiencia_pond), NULL), 4), 0)
     INTO v_cpp_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(audiencia_pond), NULL), 4), 0)
     INTO v_cpp_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE CPP REALIZADO SEM PONDERACAO
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(aud_targ), NULL), 4), 0)
     INTO v_cpp_sem_pond_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = r_me.meio
      AND meio = 'TELEVISÃO'
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(aud_targ), NULL), 4), 0)
     INTO v_cpp_sem_pond_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(aud_targ), NULL), 4), 0)
     INTO v_cpp_sem_pond_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(round(SUM(valor_unit_neg) * 0.8 / zvl(SUM(aud_targ), NULL), 4), 0)
     INTO v_cpp_sem_pond_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR ABSOLUTO REALIZADO
   SELECT nvl(SUM(valor_unit_neg) * 0.8, 0)
     INTO v_valor_abs_q1_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(SUM(valor_unit_neg) * 0.8, 0)
     INTO v_valor_abs_q2_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(SUM(valor_unit_neg) * 0.8, 0)
     INTO v_valor_abs_q3_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(SUM(valor_unit_neg) * 0.8, 0)
     INTO v_valor_abs_q4_real
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR ABSOLUTO META
   SELECT nvl(SUM(audiencia_pond) * r_me.cpp_q1, 0)
     INTO v_valor_abs_q1_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(SUM(audiencia_pond) * r_me.cpp_q2, 0)
     INTO v_valor_abs_q2_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(SUM(audiencia_pond) * r_me.cpp_q3, 0)
     INTO v_valor_abs_q3_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(SUM(audiencia_pond) * r_me.cpp_q4, 0)
     INTO v_valor_abs_q4_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- CALCULO DE VALOR ABSOLUTO SEM PONDERACAO META
   SELECT nvl(SUM(aud_targ) * r_me.cpp_q1, 0)
     INTO v_valor_abs_sem_pond_q1_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(SUM(aud_targ) * r_me.cpp_q2, 0)
     INTO v_valor_abs_sem_pond_q2_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(SUM(aud_targ) * r_me.cpp_q3, 0)
     INTO v_valor_abs_sem_pond_q3_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(SUM(aud_targ) * r_me.cpp_q4, 0)
     INTO v_valor_abs_sem_pond_q4_meta
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = 'TELEVISÃO'
      AND meio = r_me.meio
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   --
   -- VERIFICA SE TEVE AUDIENCIA NO QUARTER
   SELECT nvl(SUM(aud_targ), 0)
     INTO v_aud_targ_q1
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = r_me.meio
      AND meio = 'TELEVISÃO'
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
   --
   SELECT nvl(SUM(aud_targ), 0)
     INTO v_aud_targ_q2
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = r_me.meio
      AND meio = 'TELEVISÃO'
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
   --
   SELECT nvl(SUM(aud_targ), 0)
     INTO v_aud_targ_q3
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = r_me.meio
      AND meio = 'TELEVISÃO'
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
   --
   SELECT nvl(SUM(aud_targ), 0)
     INTO v_aud_targ_q4
     FROM mi_pi
    WHERE empresa_id = p_empresa_id
      AND flag_descartar = 'N'
      AND ano = v_ano
      AND meio = r_me.meio
      AND meio = 'TELEVISÃO'
      AND nvl(target, 'ZZZZZ') = nvl(r_me.target, 'ZZZZZ')
      AND nvl(rede, 'ZZZZZ') = nvl(r_me.rede, 'ZZZZZ')
      AND nvl(praca, 'ZZZZZ') = nvl(r_me.praca, 'ZZZZZ')
      AND mi_daypart_id = r_me.mi_daypart_id
      AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   /*
       --
       -- CALCULO DE VALOR ABSOLUTO SALDO
       SELECT NVL((SUM(audiencia_pond)*r_me.cpp_q1) - (SUM(valor_unit_neg)*0.8),0)
         INTO v_valor_abs_q1_saldo
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'TELEVISÃO'
          AND meio = r_me.meio
          AND target = r_me.target
          AND praca = r_me.praca
          AND rede = r_me.rede
          AND mi_daypart_id = r_me.mi_daypart_id
          AND periodo BETWEEN v_data_q1_ini AND v_data_q1_fim;
       --
       SELECT NVL((SUM(audiencia_pond)*r_me.cpp_q2) - (SUM(valor_unit_neg)*0.8),0)
         INTO v_valor_abs_q2_saldo
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'TELEVISÃO'
          AND meio = r_me.meio
          AND target = r_me.target
          AND praca = r_me.praca
          AND rede = r_me.rede
          AND mi_daypart_id = r_me.mi_daypart_id
          AND periodo BETWEEN v_data_q2_ini AND v_data_q2_fim;
       --
       SELECT NVL((SUM(audiencia_pond)*r_me.cpp_q3) - (SUM(valor_unit_neg)*0.8),0)
         INTO v_valor_abs_q3_saldo
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'TELEVISÃO'
          AND meio = r_me.meio
          AND target = r_me.target
          AND praca = r_me.praca
          AND rede = r_me.rede
          AND mi_daypart_id = r_me.mi_daypart_id
          AND periodo BETWEEN v_data_q3_ini AND v_data_q3_fim;
       --
       SELECT NVL((SUM(audiencia_pond)*r_me.cpp_q4) - (SUM(valor_unit_neg)*0.8),0)
         INTO v_valor_abs_q4_saldo
         FROM mi_pi
        WHERE empresa_id = p_empresa_id
          AND flag_descartar = 'N'
          AND ano = v_ano
          AND meio = 'TELEVISÃO'
          AND meio = r_me.meio
          AND target = r_me.target
          AND praca = r_me.praca
          AND rede = r_me.rede
          AND mi_daypart_id = r_me.mi_daypart_id
          AND periodo BETWEEN v_data_q4_ini AND v_data_q4_fim;
   */
   --
   UPDATE mi_metas_tv
      SET cpp_q1_real                = v_cpp_q1_real,
          cpp_q2_real                = v_cpp_q2_real,
          cpp_q3_real                = v_cpp_q3_real,
          cpp_q4_real                = v_cpp_q4_real,
          cpp_sem_pond_q1_real       = v_cpp_sem_pond_q1_real,
          cpp_sem_pond_q2_real       = v_cpp_sem_pond_q2_real,
          cpp_sem_pond_q3_real       = v_cpp_sem_pond_q3_real,
          cpp_sem_pond_q4_real       = v_cpp_sem_pond_q4_real,
          valor_abs_q1_real          = v_valor_abs_q1_real,
          valor_abs_q2_real          = v_valor_abs_q2_real,
          valor_abs_q3_real          = v_valor_abs_q3_real,
          valor_abs_q4_real          = v_valor_abs_q4_real,
          valor_abs_q1_meta          = v_valor_abs_q1_meta,
          valor_abs_q2_meta          = v_valor_abs_q2_meta,
          valor_abs_q3_meta          = v_valor_abs_q3_meta,
          valor_abs_q4_meta          = v_valor_abs_q4_meta,
          valor_abs_sem_pond_q1_meta = v_valor_abs_sem_pond_q1_meta,
          valor_abs_sem_pond_q2_meta = v_valor_abs_sem_pond_q2_meta,
          valor_abs_sem_pond_q3_meta = v_valor_abs_sem_pond_q3_meta,
          valor_abs_sem_pond_q4_meta = v_valor_abs_sem_pond_q4_meta,
          aud_targ_q1                = v_aud_targ_q1,
          aud_targ_q2                = v_aud_targ_q2,
          aud_targ_q3                = v_aud_targ_q3,
          aud_targ_q4                = v_aud_targ_q4
    WHERE mi_metas_tv_id = r_me.mi_metas_tv_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_tv_calcular;
 --
 --
 PROCEDURE metas_tv_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 10/06/2019
  -- DESCRICAO: carrega tabela MI_METAS_TV
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
  p_ano               IN VARCHAR2,
  p_meio              IN VARCHAR2,
  p_meio_compl        IN VARCHAR2,
  p_target            IN VARCHAR2,
  p_rede              IN VARCHAR2,
  p_praca             IN VARCHAR2,
  p_daypart           IN VARCHAR2,
  p_cpp_q1            IN VARCHAR2,
  p_cpp_q2            IN VARCHAR2,
  p_cpp_q3            IN VARCHAR2,
  p_cpp_q4            IN VARCHAR2,
  p_trp_q1            IN VARCHAR2,
  p_trp_q2            IN VARCHAR2,
  p_trp_q3            IN VARCHAR2,
  p_trp_q4            IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt             INTEGER;
  v_ok             INTEGER;
  v_exception      EXCEPTION;
  v_mi_metas_tv_id mi_metas_tv.mi_metas_tv_id%TYPE;
  v_ano            mi_metas_tv.ano%TYPE;
  v_praca          mi_metas_tv.praca%TYPE;
  v_cpp_q1         mi_metas_tv.cpp_q1%TYPE;
  v_cpp_q2         mi_metas_tv.cpp_q2%TYPE;
  v_cpp_q3         mi_metas_tv.cpp_q3%TYPE;
  v_cpp_q4         mi_metas_tv.cpp_q4%TYPE;
  v_trp_q1         mi_metas_tv.trp_q1%TYPE;
  v_trp_q2         mi_metas_tv.trp_q2%TYPE;
  v_trp_q3         mi_metas_tv.trp_q3%TYPE;
  v_trp_q4         mi_metas_tv.trp_q4%TYPE;
  v_mi_daypart_id  mi_metas_tv.mi_daypart_id%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  IF length(TRIM(p_meio)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo MEIO não pode ter mais que 100 caracteres (' || p_meio || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_meio_compl)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo MEIO_COMPL não pode ter mais que 100 caracteres (' || p_meio_compl || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_target)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TARGET (Audience) não pode ter mais que 100 caracteres (' || p_target || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_rede)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo REDE (Channel) não pode ter mais que 100 caracteres (' || p_rede || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_praca)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA (Market) não pode ter mais que 100 caracteres (' || p_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_praca := upper(TRIM(REPLACE(p_praca, '  ', ' ')));
  IF v_praca IS NULL THEN
   v_praca := 'NACIONAL';
  END IF;
  --
  IF length(TRIM(p_daypart)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo DAYPART não pode ter mais que 100 caracteres (' || p_daypart || ').';
   RAISE v_exception;
  END IF;
  --
  --
  IF mi_carga_pkg.numero_validar(p_cpp_q1) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CPP_Q1 inválido (' || p_cpp_q1 || ').';
   RAISE v_exception;
  END IF;
  --
  v_cpp_q1 := mi_carga_pkg.numero_converter(p_cpp_q1);
  --
  IF mi_carga_pkg.numero_validar(p_cpp_q2) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CPP_Q2 inválido (' || p_cpp_q2 || ').';
   RAISE v_exception;
  END IF;
  --
  v_cpp_q2 := mi_carga_pkg.numero_converter(p_cpp_q2);
  --
  IF mi_carga_pkg.numero_validar(p_cpp_q3) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CPP_Q3 inválido (' || p_cpp_q3 || ').';
   RAISE v_exception;
  END IF;
  --
  v_cpp_q3 := mi_carga_pkg.numero_converter(p_cpp_q3);
  --
  IF mi_carga_pkg.numero_validar(p_cpp_q4) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CPP_Q4 inválido (' || p_cpp_q4 || ').';
   RAISE v_exception;
  END IF;
  --
  v_cpp_q4 := mi_carga_pkg.numero_converter(p_cpp_q4);
  --
  --
  IF mi_carga_pkg.numero_validar(p_trp_q1) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TRP_Q1 inválido (' || p_trp_q1 || ').';
   RAISE v_exception;
  END IF;
  --
  v_trp_q1 := mi_carga_pkg.numero_converter(p_trp_q1);
  --
  IF mi_carga_pkg.numero_validar(p_trp_q2) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TRP_Q2 inválido (' || p_trp_q2 || ').';
   RAISE v_exception;
  END IF;
  --
  v_trp_q2 := mi_carga_pkg.numero_converter(p_trp_q2);
  --
  IF mi_carga_pkg.numero_validar(p_trp_q3) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TRP_Q3 inválido (' || p_trp_q3 || ').';
   RAISE v_exception;
  END IF;
  --
  v_trp_q3 := mi_carga_pkg.numero_converter(p_trp_q3);
  --
  IF mi_carga_pkg.numero_validar(p_trp_q4) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TRP_Q4 inválido (' || p_trp_q4 || ').';
   RAISE v_exception;
  END IF;
  --
  v_trp_q4 := mi_carga_pkg.numero_converter(p_trp_q4);
  --
  v_mi_daypart_id := daypart_id_retornar(p_empresa_id, p_daypart, NULL);
  --
  IF v_mi_daypart_id IS NULL THEN
   SELECT MAX(mi_daypart_id)
     INTO v_mi_daypart_id
     FROM mi_daypart
    WHERE empresa_id = p_empresa_id
      AND nome LIKE 'ND%';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_metas_tv.nextval
    INTO v_mi_metas_tv_id
    FROM dual;
  --
  INSERT INTO mi_metas_tv
   (mi_metas_tv_id,
    empresa_id,
    mi_carga_id,
    mi_daypart_id,
    ano,
    data_carga,
    meio,
    meio_compl,
    target,
    rede,
    praca,
    daypart,
    cpp_q1,
    cpp_q2,
    cpp_q3,
    cpp_q4,
    trp_q1,
    trp_q2,
    trp_q3,
    trp_q4,
    flag_sem_meta)
  VALUES
   (v_mi_metas_tv_id,
    p_empresa_id,
    p_mi_carga_id,
    v_mi_daypart_id,
    v_ano,
    SYSDATE,
    TRIM(p_meio),
    TRIM(p_meio_compl),
    TRIM(p_target),
    TRIM(p_rede),
    v_praca,
    TRIM(p_daypart),
    v_cpp_q1,
    v_cpp_q2,
    v_cpp_q3,
    v_cpp_q4,
    v_trp_q1,
    v_trp_q2,
    v_trp_q3,
    v_trp_q4,
    'N');
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END metas_tv_carregar;
 --
 --
 PROCEDURE pi_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 04/06/2019
  -- DESCRICAO: limpa tabela MI_PI para o periodo especificado (mes/ano: MM/YYYY)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_periodo           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_periodo   mi_pi.periodo%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_periodo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Período inválido (' || p_periodo || ').';
   RAISE v_exception;
  END IF;
  --
  v_periodo := data_converter('01' || p_periodo);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mi_pi
   WHERE periodo = v_periodo
     AND empresa_id = p_empresa_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END pi_limpar;
 --
 --
 PROCEDURE pi_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 04/06/2019
  -- DESCRICAO: carrega tabela MI_PI
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_mi_carga_id        IN mi_carga.mi_carga_id%TYPE,
  p_periodo            IN VARCHAR2,
  p_cod_cliente        IN VARCHAR2,
  p_cliente            IN VARCHAR2,
  p_cod_produto        IN VARCHAR2,
  p_produto            IN VARCHAR2,
  p_num_ap             IN VARCHAR2,
  p_num_pi             IN VARCHAR2,
  p_periodo_tab        IN VARCHAR2,
  p_campanha           IN VARCHAR2,
  p_tipo_pi            IN VARCHAR2,
  p_meio               IN VARCHAR2,
  p_cod_emissora       IN VARCHAR2,
  p_rede               IN VARCHAR2,
  p_uf                 IN VARCHAR2,
  p_cod_praca          IN VARCHAR2,
  p_praca              IN VARCHAR2,
  p_cod_veiculo        IN VARCHAR2,
  p_veiculo            IN VARCHAR2,
  p_cod_representante  IN VARCHAR2,
  p_representante      IN VARCHAR2,
  p_cnpj_representante IN VARCHAR2,
  p_faturavel          IN VARCHAR2,
  p_cod_programa       IN VARCHAR2,
  p_descricao          IN VARCHAR2,
  p_negociacao         IN VARCHAR2,
  p_hora_inicio        IN VARCHAR2,
  p_hora_fim           IN VARCHAR2,
  p_titulo             IN VARCHAR2,
  p_formato            IN VARCHAR2,
  p_cod_tipo_comerc    IN VARCHAR2,
  p_tipo_comercial     IN VARCHAR2,
  p_data               IN VARCHAR2,
  p_valor_unit_tab     IN VARCHAR2,
  p_perc_negoc         IN VARCHAR2,
  p_valor_unit_neg     IN VARCHAR2,
  p_aud_dom            IN VARCHAR2,
  p_target             IN VARCHAR2,
  p_aud_targ           IN VARCHAR2,
  p_tot_ins            IN VARCHAR2,
  p_qtd_impressoes     IN VARCHAR2,
  p_valor_total        IN VARCHAR2,
  p_semana_ano         IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  --
  v_qt                INTEGER;
  v_ok                INTEGER;
  v_exception         EXCEPTION;
  v_mi_pi_id          mi_pi.mi_pi_id%TYPE;
  v_periodo           mi_pi.periodo%TYPE;
  v_ano               mi_pi.ano%TYPE;
  v_cod_cliente       mi_pi.cod_cliente%TYPE;
  v_cod_produto       mi_pi.cod_produto%TYPE;
  v_num_ap            mi_pi.num_ap%TYPE;
  v_num_pi            mi_pi.num_pi%TYPE;
  v_cod_emissora      mi_pi.cod_emissora%TYPE;
  v_cod_praca         mi_pi.cod_praca%TYPE;
  v_cod_veiculo       mi_pi.cod_veiculo%TYPE;
  v_veiculo           mi_pi.veiculo%TYPE;
  v_negociacao        mi_pi.negociacao%TYPE;
  v_praca             mi_pi.praca%TYPE;
  v_cod_representante mi_pi.cod_representante%TYPE;
  v_data              mi_pi.data%TYPE;
  v_valor_unit_tab    mi_pi.valor_unit_tab%TYPE;
  v_perc_negoc        mi_pi.perc_negoc%TYPE;
  v_valor_unit_neg    mi_pi.valor_unit_neg%TYPE;
  v_aud_dom           mi_pi.aud_dom%TYPE;
  v_aud_targ          mi_pi.aud_targ%TYPE;
  v_tot_ins           mi_pi.tot_ins%TYPE;
  v_qtd_impressoes    mi_pi.qtd_impressoes%TYPE;
  v_valor_total       mi_pi.valor_total%TYPE;
  v_semana_ano        mi_pi.semana_ano%TYPE;
  v_flag_descartar    mi_pi.flag_descartar%TYPE;
  v_audiencia_pond    mi_pi.audiencia_pond%TYPE;
  v_cpp_pond          mi_pi.cpp_pond%TYPE;
  v_fator             mi_crit_sec.fator%TYPE;
  v_segundos          mi_crit_sec.segundos%TYPE;
  v_mi_daypart_id     mi_pi.mi_daypart_id%TYPE;
  v_dia_sem           VARCHAR2(20);
  v_hora_inicio       VARCHAR2(20);
  v_hora_fim          VARCHAR2(20);
  v_flag_bonificacao  mi_pi.flag_bonificacao%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_periodo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01/' || p_periodo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Período inválido (' || p_periodo || ').';
   RAISE v_exception;
  END IF;
  --
  v_periodo := data_converter('01/' || p_periodo);
  v_ano     := to_number(to_char(v_periodo, 'YYYY'));
  --
  IF inteiro_validar(p_cod_cliente) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_CLIENTE inválido (' || p_cod_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_cliente := to_number(p_cod_cliente);
  --
  IF length(TRIM(p_cliente)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CLIENTE não pode ter mais que 100 caracteres (' || p_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_cod_produto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_PRODUTO inválido (' || p_cod_produto || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_produto := to_number(p_cod_produto);
  --
  IF length(TRIM(p_produto)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRODUTO não pode ter mais que 100 caracteres (' || p_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_ap) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo NUM_AP inválido (' || p_num_ap || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_ap := to_number(p_num_ap);
  --
  IF inteiro_validar(p_num_pi) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo NUM_PI inválido (' || p_num_pi || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_pi := to_number(p_num_pi);
  --
  IF length(TRIM(p_periodo_tab)) > 40 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PERIODO_TAB não pode ter mais que 40 caracteres (' || p_periodo_tab || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_campanha)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CAMPANHA não pode ter mais que 100 caracteres (' || p_campanha || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_tipo_pi)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TIPO_PI não pode ter mais que 100 caracteres (' || p_tipo_pi || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_meio)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo MEIO não pode ter mais que 100 caracteres (' || p_meio || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_cod_emissora) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_EMISSORA inválido (' || p_cod_emissora || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_emissora := to_number(p_cod_emissora);
  --
  IF length(TRIM(p_rede)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo REDE não pode ter mais que 100 caracteres (' || p_rede || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_uf)) > 2 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo UF não pode ter mais que 2 caracteres (' || p_uf || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_cod_praca) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_PRACA inválido (' || p_cod_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_praca := to_number(p_cod_praca);
  --
  IF length(TRIM(p_praca)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PRACA não pode ter mais que 100 caracteres (' || p_praca || ').';
   RAISE v_exception;
  END IF;
  --
  v_praca := upper(TRIM(REPLACE(p_praca, '  ', ' ')));
  --
  IF inteiro_validar(p_cod_veiculo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_VEICULO inválido (' || p_cod_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_veiculo := to_number(p_cod_veiculo);
  --
  IF length(TRIM(p_veiculo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VEICULO não pode ter mais que 100 caracteres (' || p_veiculo || ').';
   RAISE v_exception;
  END IF;
  --
  v_veiculo := TRIM(upper(acento_retirar(p_veiculo)));
  v_veiculo := TRIM(REPLACE(v_veiculo, '  ', ' '));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'OOH -', ''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'RD -', ''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'OUT -', ''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JN -', ''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JN ', ''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'RV -', ''));
  --v_veiculo := TRIM(REPLACE(v_veiculo,'IN -',''));
  --v_veiculo := TRIM(REPLACE(v_veiculo,'INT -',''));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'ACTION OOH', 'ACTION'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'ATIVA MULTICANAL', 'ATIVA'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'ELETROMIDIA S.A', 'ELETROMIDIA'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JCDECAUX BRASIL S/A', 'JCDECAUX'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JCDECAUX SALVADOR', 'JCDECAUX'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JC DECAUX', 'JCDECAUX'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JC DECAUX BRASIL', 'JCDECAUX'));
  v_veiculo := TRIM(REPLACE(v_veiculo, 'JCDECAUX BRASIL', 'JCDECAUX'));
  --
  IF inteiro_validar(p_cod_representante) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_REPRESENTANTE inválido (' || p_cod_representante || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_representante := to_number(p_cod_representante);
  --
  IF length(TRIM(p_representante)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo REPRESENTANTE não pode ter mais que 100 caracteres (' ||
                 p_representante || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cnpj_representante)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo CNPJ_REPRESENTANTE não pode ter mais que 20 caracteres (' ||
                 p_cnpj_representante || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_faturavel)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FATURAVEL não pode ter mais que 10 caracteres (' || p_faturavel || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_programa)) > 40 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_PROGRAMA não pode ter mais que 40 caracteres (' || p_cod_programa || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo DESCRICAO não pode ter mais que 100 caracteres (' || p_descricao || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_negociacao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo NEGOCIACAO não pode ter mais que 100 caracteres (' || p_descricao || ').';
   RAISE v_exception;
  END IF;
  --
  v_negociacao := TRIM(upper(acento_retirar(p_negociacao)));
  v_negociacao := TRIM(REPLACE(v_negociacao, '  ', ' '));
  v_negociacao := TRIM(REPLACE(v_negociacao, 'CPVT', 'CPV'));
  --
  IF length(TRIM(p_hora_inicio)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo HORA_INICIO não pode ter mais que 10 caracteres (' || p_hora_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  v_hora_inicio := TRIM(p_hora_inicio);
  IF instr(v_hora_inicio, ':') = 2 THEN
   v_hora_inicio := '0' || v_hora_inicio;
  END IF;
  --
  IF hora_validar(v_hora_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo HORA_INICIO inválido (' || p_hora_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_hora_fim)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo HORA_FIM não pode ter mais que 10 caracteres (' || p_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_hora_fim := TRIM(p_hora_fim);
  IF instr(v_hora_fim, ':') = 2 THEN
   v_hora_fim := '0' || v_hora_fim;
  END IF;
  --
  IF hora_validar(v_hora_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo HORA_FIM inválido (' || p_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_titulo)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TITULO não pode ter mais que 100 caracteres (' || p_titulo || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_formato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo FORMATO não pode ter mais que 100 caracteres (' || p_formato || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_tipo_comerc)) > 40 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo COD_TIPO_COMERC não pode ter mais que 40 caracteres (' ||
                 p_cod_tipo_comerc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_tipo_comercial)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TIPO_COMERCIAL não pode ter mais que 100 caracteres (' ||
                 p_tipo_comercial || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo DATA inválido (' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_tab) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_TAB inválido (' || p_valor_unit_tab || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_tab := mi_carga_pkg.numero_converter(p_valor_unit_tab);
  --
  IF mi_carga_pkg.numero_validar(p_perc_negoc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo PERC_NEGOC inválido (' || p_perc_negoc || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_negoc := mi_carga_pkg.numero_converter(p_perc_negoc);
  --
  IF mi_carga_pkg.numero_validar(p_valor_unit_neg) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_UNIT_NEG inválido (' || p_valor_unit_neg || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_unit_neg := mi_carga_pkg.numero_converter(p_valor_unit_neg);
  --
  IF mi_carga_pkg.numero_validar(p_aud_dom) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo AUD_DOM inválido (' || p_aud_dom || ').';
   RAISE v_exception;
  END IF;
  --
  v_aud_dom := mi_carga_pkg.numero_converter(p_aud_dom);
  --
  IF length(TRIM(p_target)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TARGET não pode ter mais que 100 caracteres (' || p_target || ').';
   RAISE v_exception;
  END IF;
  --
  IF mi_carga_pkg.numero_validar(p_aud_targ) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo AUD_TARG inválido (' || p_aud_targ || ').';
   RAISE v_exception;
  END IF;
  --
  v_aud_targ := mi_carga_pkg.numero_converter(p_aud_targ);
  --
  IF mi_carga_pkg.numero_validar(p_tot_ins) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo TOT_INS inválido (' || p_tot_ins || ').';
   RAISE v_exception;
  END IF;
  --
  v_tot_ins := mi_carga_pkg.numero_converter(p_tot_ins);
  --
  IF mi_carga_pkg.numero_validar(p_qtd_impressoes) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo QTD_IMPRESSOES inválido (' || p_qtd_impressoes || ').';
   RAISE v_exception;
  END IF;
  --
  v_qtd_impressoes := mi_carga_pkg.numero_converter(p_qtd_impressoes);
  --
  IF mi_carga_pkg.numero_validar(p_valor_total) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo VALOR_TOTAL inválido (' || p_valor_total || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_total := mi_carga_pkg.numero_converter(p_valor_total);
  --
  IF inteiro_validar(p_semana_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Campo SEMANA_ANO inválido (' || p_semana_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_semana_ano := to_number(p_semana_ano);
  --
  ------------------------------------------------------------
  -- verifica registros a serem descartados
  ------------------------------------------------------------
  v_flag_descartar := 'N';
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mi_carga_descarte
   WHERE empresa_id = p_empresa_id
     AND tabela = 'MI_PI'
     AND atributo = 'TIPO_PI'
     AND upper(valor) = upper(TRIM(p_tipo_pi));
  --
  IF v_qt > 0 THEN
   v_flag_descartar := 'S';
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mi_carga_descarte
   WHERE empresa_id = p_empresa_id
     AND tabela = 'MI_PI'
     AND atributo = 'REDE'
     AND upper(valor) = upper(TRIM(p_rede));
  --
  IF v_qt > 0 THEN
   v_flag_descartar := 'S';
  END IF;
  --
  IF TRIM(p_descricao) IN ('FUTEBOL SEGUNDA',
                           'FUTEBOL TERÇA',
                           'FUTEBOL QUARTA',
                           'FUTEBOL QUINTA',
                           'FUTEBOL SEXTA',
                           'FUTEBOL SABADO',
                           'FUTEBOL DOMINGO') THEN
   -- tratamento especial para futebol
   SELECT decode(TRIM(p_descricao),
                 'FUTEBOL SEGUNDA',
                 'Monday',
                 'FUTEBOL TERÇA',
                 'Tuesday',
                 'FUTEBOL QUARTA',
                 'Wednesday',
                 'FUTEBOL QUINTA',
                 'Thursday',
                 'FUTEBOL SEXTA',
                 'Friday',
                 'FUTEBOL SABADO',
                 'Saturday',
                 'FUTEBOL DOMINGO',
                 'Sunday')
     INTO v_dia_sem
     FROM dual;
   --
   v_mi_daypart_id := daypart_id_retornar(p_empresa_id, v_dia_sem, NULL);
  ELSIF TRIM(p_target) LIKE '%PAY TV%' THEN
   -- tenta pelo nome da faixa (sem a rede)
   v_mi_daypart_id := daypart_id_retornar(p_empresa_id, p_descricao, NULL);
   --
   IF v_mi_daypart_id IS NULL THEN
    -- tenta pelo horario de inicio + rede
    v_mi_daypart_id := daypart_id_retornar(p_empresa_id, v_hora_inicio, p_rede);
   END IF;
  ELSE
   v_mi_daypart_id := daypart_id_retornar(p_empresa_id, v_hora_inicio, NULL);
  END IF;
  --
  IF v_mi_daypart_id IS NULL OR v_mi_daypart_id = 99999 THEN
   SELECT MAX(mi_daypart_id)
     INTO v_mi_daypart_id
     FROM mi_daypart
    WHERE empresa_id = p_empresa_id
      AND nome LIKE 'ND%';
  END IF;
  --
  v_flag_bonificacao := 'N';
  IF upper(p_tipo_pi) LIKE 'BONIFICAÇÃO%' OR upper(p_tipo_pi) LIKE 'REAPLICAÇÃO%' THEN
   v_flag_bonificacao := 'S';
  END IF;
  --
  ------------------------------------------------------------
  -- calculos
  ------------------------------------------------------------
  v_audiencia_pond := v_aud_targ;
  v_cpp_pond       := NULL;
  --
  IF inteiro_validar(TRIM(p_formato)) = 1 THEN
   v_segundos := nvl(to_number(TRIM(p_formato)), 0);
   --
   SELECT MAX(fator)
     INTO v_fator
     FROM mi_crit_sec
    WHERE empresa_id = p_empresa_id
      AND segundos = v_segundos;
   --
   IF v_fator IS NOT NULL THEN
    v_audiencia_pond := round(v_aud_targ * v_fator, 4);
   END IF;
  END IF;
  --
  IF nvl(v_audiencia_pond, 0) > 0 THEN
   v_cpp_pond := round(v_valor_unit_neg * 0.8 / v_audiencia_pond, 4);
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mi_pi.nextval
    INTO v_mi_pi_id
    FROM dual;
  --
  INSERT INTO mi_pi
   (mi_pi_id,
    empresa_id,
    mi_carga_id,
    mi_daypart_id,
    periodo,
    ano,
    data_carga,
    cod_cliente,
    cliente,
    cod_produto,
    produto,
    num_ap,
    num_pi,
    periodo_tab,
    campanha,
    tipo_pi,
    meio,
    cod_emissora,
    rede,
    uf,
    cod_praca,
    praca,
    cod_veiculo,
    veiculo,
    cod_representante,
    representante,
    cnpj_representante,
    faturavel,
    cod_programa,
    descricao,
    negociacao,
    hora_inicio,
    hora_fim,
    titulo,
    formato,
    cod_tipo_comerc,
    tipo_comercial,
    data,
    valor_unit_tab,
    perc_negoc,
    valor_unit_neg,
    aud_dom,
    target,
    aud_targ,
    tot_ins,
    qtd_impressoes,
    valor_total,
    semana_ano,
    flag_descartar,
    audiencia_pond,
    cpp_pond,
    flag_bonificacao)
  VALUES
   (v_mi_pi_id,
    p_empresa_id,
    p_mi_carga_id,
    v_mi_daypart_id,
    v_periodo,
    v_ano,
    SYSDATE,
    v_cod_cliente,
    TRIM(p_cliente),
    v_cod_produto,
    TRIM(p_produto),
    v_num_ap,
    v_num_pi,
    TRIM(p_periodo_tab),
    TRIM(p_campanha),
    TRIM(p_tipo_pi),
    TRIM(p_meio),
    v_cod_emissora,
    TRIM(p_rede),
    TRIM(p_uf),
    v_cod_praca,
    TRIM(v_praca),
    v_cod_veiculo,
    TRIM(v_veiculo),
    v_cod_representante,
    TRIM(p_representante),
    TRIM(p_cnpj_representante),
    TRIM(p_faturavel),
    TRIM(p_cod_programa),
    TRIM(p_descricao),
    v_negociacao,
    TRIM(v_hora_inicio),
    TRIM(v_hora_fim),
    TRIM(p_titulo),
    TRIM(p_formato),
    TRIM(p_cod_tipo_comerc),
    TRIM(p_tipo_comercial),
    v_data,
    v_valor_unit_tab,
    v_perc_negoc,
    v_valor_unit_neg,
    v_aud_dom,
    TRIM(p_target),
    v_aud_targ,
    v_tot_ins,
    v_qtd_impressoes,
    v_valor_total,
    v_semana_ano,
    v_flag_descartar,
    v_audiencia_pond,
    v_cpp_pond,
    v_flag_bonificacao);
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END pi_carregar;
 --
 --
 PROCEDURE pi_descartar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 04/07/2019
  -- DESCRICAO: marca registros na tabela MI_PI como descarte (nao usados nos calculos).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ano               IN VARCHAR2,
  p_vetor_num_pi      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt           INTEGER;
  v_ok           INTEGER;
  v_exception    EXCEPTION;
  v_ano          mi_pi.ano%TYPE;
  v_num_pi       mi_pi.num_pi%TYPE;
  v_delimitador  CHAR(1);
  v_num_pi_char  VARCHAR2(40);
  v_vetor_num_pi VARCHAR2(4000);
  --
 BEGIN
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano inválido (' || p_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_ano := to_number(p_ano);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- desmarca PIs antigas
  UPDATE mi_pi pi
     SET flag_descartar = 'N'
   WHERE EXISTS (SELECT 1
            FROM mi_pi_descarte de
           WHERE pi.empresa_id = de.empresa_id
             AND pi.ano = de.ano
             AND pi.num_pi = de.num_pi)
     AND empresa_id = p_empresa_id
     AND ano = v_ano;
  --
  DELETE FROM mi_pi_descarte
   WHERE empresa_id = p_empresa_id
     AND ano = v_ano;
  --
  v_vetor_num_pi := p_vetor_num_pi;
  v_delimitador  := '|';
  --
  -- marca PIs a serem descartadas
  WHILE nvl(length(rtrim(v_vetor_num_pi)), 0) > 0
  LOOP
   v_num_pi_char := prox_valor_retornar(v_vetor_num_pi, v_delimitador);
   --
   IF inteiro_validar(v_num_pi_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Campo NUM_PI inválido (' || v_num_pi_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_num_pi := to_number(v_num_pi_char);
   --
   UPDATE mi_pi
      SET flag_descartar = 'S'
    WHERE empresa_id = p_empresa_id
      AND ano = v_ano
      AND num_pi = v_num_pi;
   --
   INSERT INTO mi_pi_descarte
    (empresa_id,
     ano,
     num_pi)
   VALUES
    (p_empresa_id,
     v_ano,
     v_num_pi);
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END pi_descartar;
 --
 --
 FUNCTION numero_validar
 -----------------------------------------------------------------------
  --   NUMERO_VALIDAR
  --
  --   Descricao: funcao que verifica se um string e' um numero valido,
  --   do tipo DOUBLE/FLOAT. Retorna '1' caso seja valido, e '0' caso
  --   nao seja. Para um string igual a NULL, retorna '1'.
  --   (OBS: trabalha c/ virgula como decimal e nao aceita ponto como
  --   separador de milhar).
  -----------------------------------------------------------------------
 (p_numero IN VARCHAR2) RETURN INTEGER IS
  v_ok          INTEGER;
  v_numero_char VARCHAR2(30);
  v_numero      NUMBER;
  v_pos         INTEGER;
 BEGIN
  v_ok := 0;
  --
  IF instr(p_numero, '.') > 0 AND instr(p_numero, ',') = 0 THEN
   RETURN v_ok;
  END IF;
  --
  v_numero_char := rtrim(REPLACE(p_numero, '.', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D9999999999999',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
  v_ok     := 1;
  --
  RETURN v_ok;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END;
 --
 --
 FUNCTION numero_converter
 -----------------------------------------------------------------------
  --   NUMERO_CONVERTER
  --
  --   Descricao: função que converte um string previamente validado
  --   em numero.
  -----------------------------------------------------------------------
 (p_numero IN VARCHAR2) RETURN NUMBER IS
  v_ok          INTEGER;
  v_numero      NUMBER;
  v_numero_char VARCHAR2(30);
  --
 BEGIN
  v_numero      := NULL;
  v_numero_char := rtrim(REPLACE(p_numero, '.', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D9999999999999',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
  --
  RETURN v_numero;
 EXCEPTION
  WHEN OTHERS THEN
   v_numero := 99999999;
   RETURN v_numero;
 END;
 --
 --
 FUNCTION daypart_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/06/2019
  -- DESCRICAO: retorna o ID do daypart de um determinado horario (que deve
  --   estar no formato HH:MI ou HH:MI:SS), dia da semana, faixa ou nome.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id IN NUMBER,
  p_daypart    IN VARCHAR2,
  p_rede       IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt            INTEGER;
  v_mi_daypart_id NUMBER;
  v_exception     EXCEPTION;
  v_hora          VARCHAR2(20);
  v_data_ref1     DATE;
  v_data_ref2     DATE;
  v_data_hora     DATE;
  v_data_inicio   DATE;
  v_data_fim      DATE;
  v_tipo          VARCHAR2(10);
  --
  -- cursor de daypart para TV aberta
  CURSOR c_dp1 IS
   SELECT mi_daypart_id,
          nome,
          hora_inicio,
          hora_fim
     FROM mi_daypart
    WHERE empresa_id = p_empresa_id
      AND hora_inicio IS NOT NULL
      AND nome NOT LIKE 'FAIXA%';
  --
  -- cursor de daypart para PAYTV
  -- (pesquisa daypart pelo horario com nome de rede em metas)
  CURSOR c_dp2 IS
   SELECT mi_daypart_id,
          nome,
          hora_inicio,
          hora_fim
     FROM mi_daypart dp
    WHERE empresa_id = p_empresa_id
      AND hora_inicio IS NOT NULL
      AND nome LIKE 'FAIXA%'
      AND EXISTS (SELECT 1
             FROM mi_metas_tv mt
            WHERE mt.empresa_id = p_empresa_id
              AND mt.rede = TRIM(p_rede)
              AND mt.mi_daypart_id = dp.mi_daypart_id);
  --
  -- cursor de daypart para PAYTV
  -- (pesquisa daypart pelo horario sem a rede)
  CURSOR c_dp3 IS
   SELECT mi_daypart_id,
          nome,
          hora_inicio,
          hora_fim
     FROM mi_daypart dp
    WHERE empresa_id = p_empresa_id
      AND hora_inicio IS NOT NULL
      AND nome LIKE 'FAIXA%';
  --
 BEGIN
  v_mi_daypart_id := NULL;
  --
  IF TRIM(p_rede) IS NOT NULL THEN
   -- tv paga. Pesquisa pelo horario de inicio + rede
   v_tipo := 'HORA_REDE';
  ELSIF instr(p_daypart, ':') = 3 THEN
   -- tv aberta. Pesquisa pelo horario
   v_tipo := 'HORA';
  ELSE
   -- pesquisa pelo nome do daypart
   v_tipo := 'NOME';
  END IF;
  --
  ------------------------------------------------------------
  -- daypart TV aberta por horario
  ------------------------------------------------------------
  IF v_mi_daypart_id IS NULL AND v_tipo = 'HORA' THEN
   -- usa data do dia como referencia
   v_data_ref1 := trunc(SYSDATE);
   -- pega o dia seguinte
   v_data_ref2 := v_data_ref1 + 1;
   --
   v_hora := TRIM(p_daypart);
   IF length(v_hora) = 5 THEN
    -- completa o formato caso nao tenha vindo os segundos
    v_hora := v_hora || ':00';
   END IF;
   --
   FOR r_dp1 IN c_dp1
   LOOP
    IF v_mi_daypart_id IS NULL THEN
     v_data_inicio := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp1.hora_inicio,
                              'DD/MM/YYYY HH24:MI:SS');
     --
     IF to_number(substr(r_dp1.hora_inicio, 1, 2)) < to_number(substr(r_dp1.hora_fim, 1, 2)) THEN
      -- horario termina no mesmo dia
      v_data_fim  := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp1.hora_fim,
                             'DD/MM/YYYY HH24:MI:SS');
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp1.mi_daypart_id;
      END IF;
     ELSE
      -- horario termina no dia seguinte
      v_data_fim := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || r_dp1.hora_fim,
                            'DD/MM/YYYY HH24:MI:SS');
      --
      -- tenta com o dia de referencia
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp1.mi_daypart_id;
      END IF;
      --
      -- tenta com o dia seguinte
      v_data_hora := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp1.mi_daypart_id;
      END IF;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- daypart TV PAGA por horario (batendo o nome da rede)
  ------------------------------------------------------------
  IF v_mi_daypart_id IS NULL AND v_tipo = 'HORA_REDE' THEN
   -- usa data do dia como referencia
   v_data_ref1 := trunc(SYSDATE);
   -- pega o dia seguinte
   v_data_ref2 := v_data_ref1 + 1;
   --
   v_hora := TRIM(p_daypart);
   IF length(v_hora) = 5 THEN
    -- completa o formato caso nao tenha vindo os segundos
    v_hora := v_hora || ':00';
   END IF;
   --
   FOR r_dp2 IN c_dp2
   LOOP
    IF v_mi_daypart_id IS NULL THEN
     v_data_inicio := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp2.hora_inicio,
                              'DD/MM/YYYY HH24:MI:SS');
     --
     IF to_number(substr(r_dp2.hora_inicio, 1, 2)) < to_number(substr(r_dp2.hora_fim, 1, 2)) THEN
      -- horario termina no mesmo dia
      v_data_fim  := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp2.hora_fim,
                             'DD/MM/YYYY HH24:MI:SS');
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp2.mi_daypart_id;
      END IF;
     ELSE
      -- horario termina no dia seguinte
      v_data_fim := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || r_dp2.hora_fim,
                            'DD/MM/YYYY HH24:MI:SS');
      --
      -- tenta com o dia de referencia
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp2.mi_daypart_id;
      END IF;
      --
      -- tenta com o dia seguinte
      v_data_hora := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp2.mi_daypart_id;
      END IF;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- daypart TV PAGA por horario (sem bater o nome da rede)
  ------------------------------------------------------------
  IF v_mi_daypart_id IS NULL AND v_tipo = 'HORA_REDE' THEN
   -- usa data do dia como referencia
   v_data_ref1 := trunc(SYSDATE);
   -- pega o dia seguinte
   v_data_ref2 := v_data_ref1 + 1;
   --
   v_hora := TRIM(p_daypart);
   IF length(v_hora) = 5 THEN
    -- completa o formato caso nao tenha vindo os segundos
    v_hora := v_hora || ':00';
   END IF;
   --
   FOR r_dp3 IN c_dp3
   LOOP
    IF v_mi_daypart_id IS NULL THEN
     v_data_inicio := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp3.hora_inicio,
                              'DD/MM/YYYY HH24:MI:SS');
     --
     IF to_number(substr(r_dp3.hora_inicio, 1, 2)) < to_number(substr(r_dp3.hora_fim, 1, 2)) THEN
      -- horario termina no mesmo dia
      v_data_fim  := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || r_dp3.hora_fim,
                             'DD/MM/YYYY HH24:MI:SS');
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp3.mi_daypart_id;
      END IF;
     ELSE
      -- horario termina no dia seguinte
      v_data_fim := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || r_dp3.hora_fim,
                            'DD/MM/YYYY HH24:MI:SS');
      --
      -- tenta com o dia de referencia
      v_data_hora := to_date(to_char(v_data_ref1, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp3.mi_daypart_id;
      END IF;
      --
      -- tenta com o dia seguinte
      v_data_hora := to_date(to_char(v_data_ref2, 'DD/MM/YYYY') || ' ' || v_hora,
                             'DD/MM/YYYY HH24:MI:SS');
      --
      IF v_data_hora BETWEEN v_data_inicio AND v_data_fim THEN
       v_mi_daypart_id := r_dp3.mi_daypart_id;
      END IF;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- daypart por nome
  ------------------------------------------------------------
  IF v_mi_daypart_id IS NULL AND v_tipo = 'NOME' THEN
   SELECT MAX(mi_daypart_id)
     INTO v_mi_daypart_id
     FROM mi_daypart
    WHERE upper(nome) = upper(TRIM(p_daypart))
      AND empresa_id = p_empresa_id;
   --
   IF v_mi_daypart_id IS NULL THEN
    -- tenta achar uma varicao do nome
    SELECT MAX(d1.mi_daypart_id)
      INTO v_mi_daypart_id
      FROM mi_daypart     d1,
           mi_daypart_var d2
     WHERE d1.empresa_id = p_empresa_id
       AND d1.mi_daypart_id = d2.mi_daypart_id
       AND upper(d2.variacao) = upper(TRIM(p_daypart));
   END IF;
  END IF;
  --
  RETURN v_mi_daypart_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_mi_daypart_id := 99999;
   RETURN v_mi_daypart_id;
 END daypart_id_retornar;
 --
END; -- MI_CARGA_PKG



/
