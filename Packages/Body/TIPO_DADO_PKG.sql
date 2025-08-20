--------------------------------------------------------
--  DDL for Package Body TIPO_DADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_DADO_PKG" IS
 --
 PROCEDURE validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/02/2013
  -- DESCRICAO: valida o valor para um determinado tipo de dado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/08/2017  Novos parametros empresa_id, valor_saida.
  -- Silvia            26/04/2022  Novo parametro para ignorar teste de obrigatoriedade:
  --                               flag_ignora_obrig
  -- Silvia            03/10/2022  Novo parametro usuario_sessao_id para testar privegio.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_codigo            IN VARCHAR2,
  p_flag_obrigatorio  IN VARCHAR2,
  p_flag_ignora_obrig IN VARCHAR2,
  p_tamanho           IN NUMBER,
  p_valor             IN VARCHAR2,
  p_valor_saida       OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_tipo_dado_id tipo_dado.tipo_dado_id%TYPE;
  v_flag_tem_tam tipo_dado.flag_tem_tam%TYPE;
  v_tam_max      tipo_dado.tam_max%TYPE;
  v_valor_aux    VARCHAR2(2000);
  --
 BEGIN
  --
  -- retorna o mesmo valor como padrao
  p_valor_saida := TRIM(p_valor);
  --
  SELECT MAX(tipo_dado_id)
    INTO v_tipo_dado_id
    FROM tipo_dado
   WHERE codigo = p_codigo;
  --
  IF v_tipo_dado_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do tipo de dado inválido ( ' || p_codigo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(tam_max, 0),
         flag_tem_tam
    INTO v_tam_max,
         v_flag_tem_tam
    FROM tipo_dado
   WHERE tipo_dado_id = v_tipo_dado_id;
  --
  IF p_flag_ignora_obrig = 'N' THEN
   IF p_flag_obrigatorio = 'S' AND TRIM(p_valor) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Prenchimento obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- nao testa tamanho para MULTICKBOX pois ele eh usado para layout de colunas
  IF p_codigo NOT IN ('MULTICKBOX', 'RADBUTTON') THEN
   IF v_flag_tem_tam = 'S' AND length(TRIM(p_valor)) > p_tamanho THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O conteúdo não pode ter mais que ' || to_char(p_tamanho) || ' caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF v_tam_max > 0 AND length(TRIM(p_valor)) > v_tam_max THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O conteúdo não pode ter mais que ' || to_char(v_tam_max) || ' caracteres.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'DATA' THEN
   IF data_validar(p_valor) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'HORA' THEN
   IF hora_validar(p_valor) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Hora inválida (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'INTEIRO' THEN
   IF inteiro_validar(p_valor) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número inteiro inválido (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'MOEDA' THEN
   IF moeda_validar(p_valor) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor monetário inválido (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'DECIMAL' THEN
   IF numero_validar(p_valor) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número decimal inválido (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_codigo = 'CNPJ' THEN
   IF cnpj_pkg.validar(p_valor, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CNPJ inválido (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
   --
   -- retira eventual formatacao
   v_valor_aux := cnpj_pkg.converter(p_valor, p_empresa_id);
   -- retorna o nro formatado
   p_valor_saida := cnpj_pkg.mostrar(v_valor_aux, p_empresa_id);
  END IF;
  --
  IF p_codigo = 'CPF' THEN
   IF cpf_pkg.validar(p_valor, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CPF inválido (' || TRIM(p_valor) || ').';
    RAISE v_exception;
   END IF;
   --
   -- retira eventual formatacao
   v_valor_aux := cpf_pkg.converter(p_valor, p_empresa_id);
   -- retorna o nro formatado
   p_valor_saida := cpf_pkg.mostrar(v_valor_aux, p_empresa_id);
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END validar;
 --
--
END tipo_dado_pkg;



/
