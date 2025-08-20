--------------------------------------------------------
--  DDL for Package Body UTIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "UTIL_PKG" IS
 --
 g_key_str  VARCHAR2(20) := '8UzpL2!R)12kX+j';
 g_key_str2 VARCHAR2(20) := '8UzpL2!R)12kX+jA';
 g_key_num  VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 --
 --
 FUNCTION texto_encriptar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 16/05/2022
  -- DESCRICAO: encriptacao de texto via DBMS_CRYPTO. Caso a chave de encriptacao
  --   nao seja passada via parametro, usa a padrao definida na variavel g_key_str2
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_string IN VARCHAR2,
  p_key    IN VARCHAR2
 ) RETURN VARCHAR2 IS
  l_key            VARCHAR2(2000);
  l_mod            NUMBER := dbms_crypto.encrypt_aes128 + dbms_crypto.chain_cbc +
                             dbms_crypto.pad_pkcs5;
  l_encrypted_raw  RAW(2000);
  l_encrypted_text VARCHAR2(4000);
 BEGIN
  l_key           := nvl(p_key, g_key_str2);
  l_encrypted_raw := dbms_crypto.encrypt(utl_i18n.string_to_raw(p_string, 'AL32UTF8'),
                                         l_mod,
                                         utl_i18n.string_to_raw(l_key, 'AL32UTF8'));
  --l_encrypted_text := UTL_I18N.RAW_TO_CHAR(l_encrypted_raw, 'AL32UTF8');
  l_encrypted_text := rawtohex(l_encrypted_raw);
  RETURN l_encrypted_text;
 END texto_encriptar;
 --
 --
 FUNCTION texto_desencriptar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 16/05/2022
  -- DESCRICAO: desencriptacao de texto via DBMS_CRYPTO. A passagem da chave de
  --   encriptacao eh obrigatoria. Se nao bater, retorna o string ERRO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_string IN VARCHAR2,
  p_key    IN VARCHAR2
 ) RETURN VARCHAR2 IS
  l_key              VARCHAR2(2000);
  l_mod              NUMBER := dbms_crypto.encrypt_aes128 + dbms_crypto.chain_cbc +
                               dbms_crypto.pad_pkcs5;
  l_string_raw       RAW(2000);
  l_decrypted_raw    RAW(2000);
  l_decrypted_string VARCHAR2(2000);
 BEGIN
  IF TRIM(p_key) IS NULL OR p_key <> g_key_str2 THEN
   l_decrypted_string := 'ERRO';
   RETURN l_decrypted_string;
  END IF;
  --
  l_key := g_key_str2;
  --l_string_raw := UTL_I18N.STRING_TO_RAW(p_string, 'AL32UTF8');
  l_string_raw       := hextoraw(p_string);
  l_decrypted_raw    := dbms_crypto.decrypt(l_string_raw,
                                            l_mod,
                                            utl_i18n.string_to_raw(l_key, 'AL32UTF8'));
  l_decrypted_string := TRIM(utl_i18n.raw_to_char(l_decrypted_raw, 'AL32UTF8'));
  RETURN l_decrypted_string;
 END texto_desencriptar;
 --
 --
 /*PROCEDURE oracletext_sincronizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: PROCEDURE que sincroniza os indices criados via Oracle
  --     Text. A chamada deve ser feita via job. Codigo valido para
  --     versoes de Oracle superiores a Oracle8i.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/08/2009  Geração de evento.
  -- Silvia            04/04/2010  Troca da barra / pela \
  ------------------------------------------------------------------------------------------
  IS
  --
  CURSOR cur IS
   SELECT index_name
     FROM user_indexes
    WHERE index_type = 'DOMAIN';
  --
  v_ind_name          VARCHAR2(1024);
  v_historico_id      historico.historico_id%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_erro_cod          VARCHAR2(100);
  v_erro_msg          VARCHAR2(1000);
  v_usuario_sessao_id usuario.usuario_id%TYPE;
  v_data_hoje         DATE;
  v_data_hoje_char    VARCHAR2(40);
  v_empresa_id        empresa.empresa_id%TYPE;
  --
 BEGIN
  SELECT MIN(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  v_data_hoje      := SYSDATE;
  v_data_hoje_char := to_char(v_data_hoje, 'dd/mm/yyyy hh24:mi');
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_sessao_id);
  --
  v_identif_objeto := 'OracleText Sync ' || v_data_hoje_char;
  v_compl_histor   := 'Inicio';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'SISTEMA',
                   'ALTERAR',
                   v_identif_objeto,
                   0,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   v_erro_cod,
                   v_erro_msg);
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ctx_arquivo';
  --
  INSERT INTO ctx_arquivo
   (arquivo_id,
    empresa_id,
    nome_completo)
   SELECT DISTINCT ar.arquivo_id,
                   jo.empresa_id,
                   vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' ||
                   ar.nome_fisico
     FROM arquivo           ar,
          volume            vo,
          arquivo_documento ad,
          documento         dc,
          job               jo,
          tipo_arquivo      ti
    WHERE ar.volume_id = vo.volume_id
      AND ar.tipo_arquivo_id = ti.tipo_arquivo_id
      AND ti.codigo = 'DOCUMENTO'
      AND ar.arquivo_id = ad.arquivo_id
      AND ad.documento_id = dc.documento_id
      AND dc.job_id = jo.job_id;
  --
  INSERT INTO ctx_arquivo
   (arquivo_id,
    empresa_id,
    nome_completo)
   SELECT DISTINCT ar.arquivo_id,
                   jo.empresa_id,
                   vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' ||
                   ar.nome_fisico
     FROM arquivo       ar,
          volume        vo,
          arquivo_os    ao,
          ordem_servico os,
          job           jo,
          tipo_arquivo  ti
    WHERE ar.volume_id = vo.volume_id
      AND ar.tipo_arquivo_id = ti.tipo_arquivo_id
      AND ti.codigo = 'ORDEM_SERVICO'
      AND ar.arquivo_id = ao.arquivo_id
      AND ao.ordem_servico_id = os.ordem_servico_id
      AND os.job_id = jo.job_id;
  --
  OPEN cur;
  LOOP
   FETCH cur
   INTO v_ind_name;
   EXIT WHEN cur%NOTFOUND;
   ctx_ddl.sync_index('' || v_ind_name || '');
  END LOOP;
  CLOSE cur;
  --
  v_compl_histor := 'Fim';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'SISTEMA',
                   'ALTERAR',
                   v_identif_objeto,
                   0,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   v_erro_cod,
                   v_erro_msg);
  --
  COMMIT;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_compl_histor := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                            1,
                            200);
   evento_pkg.gerar(v_usuario_sessao_id,
                    v_empresa_id,
                    'SISTEMA',
                    'ALTERAR',
                    v_identif_objeto,
                    0,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   COMMIT;
   --
 END;*/ -- oracletext_sincronizar
 --
 --
 FUNCTION desc_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 04/10/2005
  -- DESCRICAO: retorna a descricao do dicionario correspondente ao tipo e codigo passados
  --   pelos parametros.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_tipo   IN VARCHAR2,
  p_codigo IN VARCHAR2
 ) RETURN VARCHAR2 IS
  v_desc dicionario.descricao%TYPE;
 BEGIN
  v_desc := NULL;
  --
  SELECT MAX(descricao)
    INTO v_desc
    FROM dicionario
   WHERE tipo = lower(p_tipo)
     AND codigo = upper(p_codigo);
  --
  RETURN v_desc;
 EXCEPTION
  WHEN OTHERS THEN
   v_desc := 'ERRO';
   RETURN v_desc;
 END desc_retornar;
 --
 --
 FUNCTION prox_dia_util_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/07/2006
  -- DESCRICAO: retorna o proximo dia util a partir de uma determinada data base. Caso o
  --  parametro p_flag_com_data_base seja 'S', leva em consideracao a propria data passada
  --  no parametro.     Nao leva em conta feriados (para isso existe a funcao
  --  FERIADO_PKG.PROX_DIA_UTIL_RETORNAR).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_data_base          IN DATE,
  p_flag_com_data_base IN VARCHAR2
 ) RETURN DATE IS
  v_data       DATE;
  v_dia_semana INTEGER;
 BEGIN
  v_data := trunc(p_data_base);
  --
  IF p_flag_com_data_base = 'N' THEN
   v_data := v_data + 1;
  END IF;
  --
  v_dia_semana := to_number(to_char(v_data, 'D'));
  --
  IF v_dia_semana = 7 THEN
   -- caiu num sabado
   v_data := v_data + 2;
  END IF;
  --
  IF v_dia_semana = 1 THEN
   -- caiu num domingo
   v_data := v_data + 1;
  END IF;
  --
  RETURN v_data;
 EXCEPTION
  WHEN OTHERS THEN
   v_data := NULL;
   RETURN v_data;
 END prox_dia_util_retornar;
 --
 --
 FUNCTION prox_dia_semana_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 18/10/2018
  -- DESCRICAO: retorna o proximo dia da semana a partir de uma determinada data base.
  --  Nao leva em conta feriados. p_prox_dia = de 1 a 7 (de DOM a SAB).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_data_base IN DATE,
  p_prox_dia  IN NUMBER
 ) RETURN DATE IS
  v_data       DATE;
  v_dia_semana INTEGER;
  v_exception  EXCEPTION;
 BEGIN
  IF p_data_base IS NULL OR nvl(p_prox_dia, 0) NOT BETWEEN 1 AND 7 THEN
   RAISE v_exception;
  END IF;
  --
  v_data       := trunc(p_data_base) + 1;
  v_dia_semana := nvl(p_prox_dia, 0);
  --
  WHILE to_number(to_char(v_data, 'D')) <> v_dia_semana
  LOOP
   v_data := v_data + 1;
  END LOOP;
  --
  RETURN v_data;
 EXCEPTION
  WHEN OTHERS THEN
   v_data := NULL;
   RETURN v_data;
 END prox_dia_semana_retornar;
 --
 --
 FUNCTION data_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/07/2006
  -- DESCRICAO: calcula uma data futura, a partir de uma determinada data base e do
  --   numero de dias uteis ou corridos.   Nao leva em conta feriados (para isso existe a
  --  funcao FERIADO_PKG.PROX_DIA_UTIL_RETORNAR).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_data_base    IN DATE,
  p_tipo_calculo IN VARCHAR2,
  p_num_dias     IN INTEGER
 ) RETURN DATE IS
  v_data    DATE;
  v_retorno DATE;
  v_qt      INTEGER;
 BEGIN
  v_retorno := NULL;
  --
  IF p_tipo_calculo = 'C' THEN
   IF nvl(p_num_dias, 0) < 0 THEN
    v_retorno := trunc(p_data_base);
   ELSE
    v_retorno := trunc(p_data_base) + nvl(p_num_dias, 0);
   END IF;
  ELSIF p_tipo_calculo = 'U' THEN
   v_data := trunc(p_data_base);
   v_qt   := 1;
   --
   WHILE v_qt <= p_num_dias
   LOOP
    v_data := util_pkg.prox_dia_util_retornar(v_data, 'N');
    v_qt   := v_qt + 1;
   END LOOP;
   --
   v_retorno := v_data;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_calcular;
 --
 --
 FUNCTION somar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 26/07/2006
  -- DESCRICAO: soma os numeros passados pelo vetor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_vetor_numero   IN VARCHAR2,
  p_casas_decimais IN INTEGER
 ) RETURN VARCHAR2 IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_delimitador    CHAR(1);
  v_vetor_numero   VARCHAR2(2000);
  v_numero_char    VARCHAR2(40);
  v_soma           NUMBER;
  v_soma_char      VARCHAR2(40);
  v_casas_decimais INTEGER;
  --
 BEGIN
  v_qt   := 0;
  v_soma := 0;
  --
  v_casas_decimais := nvl(p_casas_decimais, 0);
  IF v_casas_decimais > 6 THEN
   v_casas_decimais := 6;
  END IF;
  --
  v_delimitador  := '|';
  v_vetor_numero := rtrim(p_vetor_numero);
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_numero)), 0) > 0
  LOOP
   v_numero_char := prox_valor_retornar(v_vetor_numero, v_delimitador);
   --
   IF numero_validar(v_numero_char) = 0 THEN
    RAISE v_exception;
   END IF;
   --
   v_soma := v_soma + nvl(numero_converter(v_numero_char), 0);
  END LOOP;
  --
  v_soma_char := numero_mostrar(v_soma, v_casas_decimais, 'S');
  RETURN v_soma_char;
  --
 EXCEPTION
  WHEN v_exception THEN
   v_soma_char := '999999';
   RETURN v_soma_char;
  WHEN OTHERS THEN
   v_soma_char := '999999';
   RETURN v_soma_char;
 END; -- somar
 --
 --
 FUNCTION keywords_preparar
 (
  -----------------------------------------------------------------------
  --   keywords_preparar
  --
  --   Descricao: prepara o string de entrada para pesquisa com
  --     Oracle Text.
  -----------------------------------------------------------------------
  p_string IN VARCHAR2
 ) RETURN VARCHAR2 IS
  v_string VARCHAR2(4000);
 BEGIN
  v_string := TRIM(upper(p_string));
  --
  -- retira caracteres que sozinhos causam erro Oracle
  v_string := REPLACE(v_string, '*', ' ');
  v_string := REPLACE(v_string, '%', ' ');
  v_string := REPLACE(v_string, '(', ' ');
  v_string := REPLACE(v_string, ')', ' ');
  v_string := REPLACE(v_string, '|', ' ');
  v_string := REPLACE(v_string, '"', ' ');
  --
  v_string := REPLACE(v_string, '-', ' ');
  v_string := REPLACE(v_string, '&', ' ');
  v_string := REPLACE(v_string, '#', ' ');
  --
  v_string := REPLACE(v_string, ',', ' ');
  v_string := REPLACE(v_string, '>', ' ');
  v_string := REPLACE(v_string, ';', ' ');
  v_string := REPLACE(v_string, '?', ' ');
  v_string := REPLACE(v_string, '~', ' ');
  v_string := REPLACE(v_string, '[', ' ');
  v_string := REPLACE(v_string, ']', ' ');
  v_string := REPLACE(v_string, '{', ' ');
  v_string := REPLACE(v_string, '}', ' ');
  v_string := REPLACE(v_string, '!', ' ');
  v_string := REPLACE(v_string, '$', ' ');
  v_string := REPLACE(v_string, '=', ' ');
  v_string := REPLACE(v_string, '_', ' ');
  --
  v_string := REPLACE(v_string, '/', ' ');
  v_string := REPLACE(v_string, '\', ' ');
  v_string := REPLACE(v_string, ':', ' ');
  v_string := REPLACE(v_string, '.', ' ');
  v_string := REPLACE(v_string, '+', ' ');
  v_string := REPLACE(v_string, '@', ' ');
  v_string := REPLACE(v_string, chr(10), ' ');
  v_string := REPLACE(v_string, chr(13), ' ');
  --
  -- retira eventuais brancos a mais
  v_string := TRIM(REPLACE(v_string, '     ', ' '));
  v_string := TRIM(REPLACE(v_string, '    ', ' '));
  v_string := TRIM(REPLACE(v_string, '   ', ' '));
  v_string := REPLACE(v_string, '  ', ' ');
  --
  IF v_string IS NOT NULL THEN
   -- retira DO e NO no meio do texto
   v_string := TRIM(REPLACE(v_string, ' DO ', ' '));
   v_string := TRIM(REPLACE(v_string, ' NO ', ' '));
   v_string := TRIM(REPLACE(v_string, ' OR ', ' '));
   v_string := TRIM(REPLACE(v_string, ' AND ', ' '));
   --
   -- -- retira DO, NO, OR no comeco do texto
   IF substr(v_string, 1, 3) IN ('DO ', 'NO ', 'OR ') THEN
    v_string := substr(v_string, 4);
   END IF;
   --
   -- -- retira AND no comeco do texto
   IF substr(v_string, 1, 4) IN ('AND ') THEN
    v_string := substr(v_string, 5);
   END IF;
   --
   -- -- retira DO, NO, OR no fim do texto
   IF substr(v_string, length(v_string) - 2) IN (' DO', ' NO', ' OR') THEN
    v_string := TRIM(substr(v_string, 1, length(v_string) - 3));
   END IF;
   --
   -- -- retira AND no fim do texto
   IF substr(v_string, length(v_string) - 3) IN (' AND') THEN
    v_string := TRIM(substr(v_string, 1, length(v_string) - 4));
   END IF;
   --
   -- acrescenta o AND apos cada palavra
   v_string := REPLACE(v_string, ' ', ' AND ');
  END IF;
  --
  RETURN v_string;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_string := 'ERRO string';
   RETURN v_string;
 END;
 --
 --
 FUNCTION acento_municipio_retirar
 -----------------------------------------------------------------------
  --   acento_municipio_retirar
  --
  --   Descricao: dado um string, substiui as vogais acentuadas por
  --     vogais sem acento e transforma p/ uppercase (NAO MUDA o ç)
  -----------------------------------------------------------------------
 (p_string IN VARCHAR2) RETURN VARCHAR2 IS
  --
  v_string VARCHAR2(500);
  --
 BEGIN
  v_string := ltrim(rtrim(lower(p_string)));
  v_string := translate(v_string, 'áéíóúâêîôûàèìòùãõü', 'aeiouaeiouaeiouaou');
  v_string := upper(v_string);
  RETURN v_string;
 EXCEPTION
  WHEN OTHERS THEN
   v_string := 'ERRO string';
   RETURN v_string;
 END;
 --
 --
 FUNCTION transf_montar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 25/05/2016
  -- DESCRICAO: monta tabela de transformacao de numeros.
  --  p_num_sai_ini: primeiro nro de saida para a posicao 1
  --  p_pos: tamanho do nro a ser encriptado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_num_sai_ini IN NUMBER,
  p_pos         IN NUMBER
 ) RETURN transf_tab
 PIPELINED IS
  v_num_sai_ini NUMBER;
  v_num_sai     NUMBER;
 BEGIN
  v_num_sai_ini := p_num_sai_ini;
  --
  FOR i IN 0 .. 9
  LOOP
   v_num_sai := v_num_sai_ini;
   FOR j IN 1 .. p_pos
   LOOP
    PIPE ROW(transf_rec(i, j, v_num_sai));
    v_num_sai := v_num_sai + 1;
    IF v_num_sai > 9 THEN
     v_num_sai := 0;
    END IF;
   END LOOP;
   v_num_sai_ini := v_num_sai_ini + 1;
   IF v_num_sai_ini > 9 THEN
    v_num_sai_ini := 0;
   END IF;
  END LOOP;
  RETURN;
 END transf_montar;
 --
 --
 FUNCTION num_encode
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 24/05/2016
  -- DESCRICAO: codifica campo numerico com até 2 casas decimais
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/07/2022  Ajuste para numeros menores que 0,10 (0,09 ou menor)
  ------------------------------------------------------------------------------------------
 (p_numero IN NUMBER) RETURN NUMBER IS
  v_retorno      NUMBER;
  v_numero       NUMBER;
  v_tamanho      NUMBER(10);
  v_num_rand1    NUMBER(10);
  v_num_rand2    NUMBER(10);
  v_num_rand3    NUMBER(10);
  v_num_ent_char VARCHAR2(100);
  v_num_sai_char VARCHAR2(100);
  v_num_ent      NUMBER(5);
  v_num_sai      NUMBER(5);
  v_pos          NUMBER(5);
  v_saida        EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_numero IS NULL OR p_numero = 0 THEN
   v_retorno := p_numero;
   RAISE v_saida;
  END IF;
  --
  -- trata as 2 casas decimais
  v_numero := p_numero * 100;
  --
  IF v_numero <> trunc(v_numero) THEN
   v_retorno := -99999;
   RAISE v_saida;
  END IF;
  --
  v_num_ent_char := TRIM(to_char(v_numero));
  IF length(v_num_ent_char) = 1 THEN
   -- numero original menor que 0,10 (0,09 ou menor)
   -- acrescenta 1 zero a esquerda
   v_num_ent_char := '0' || v_num_ent_char;
  END IF;
  --
  -- tamanho total do string
  v_tamanho := length(v_num_ent_char);
  --
  -- troca cada digito de acordo com a tabela de transformacao
  v_pos := 1;
  WHILE v_pos <= v_tamanho
  LOOP
   v_num_ent := to_number(substr(v_num_ent_char, v_pos, 1));
   --
   SELECT MAX(num_sai)
     INTO v_num_sai
     FROM TABLE(transf_montar(3, v_tamanho))
    WHERE num_ent = v_num_ent
      AND pos = v_pos;
   --
   IF v_num_sai IS NULL THEN
    v_retorno := -99999;
    RAISE v_saida;
   END IF;
   --
   v_num_sai_char := v_num_sai_char || to_char(v_num_sai);
   v_pos          := v_pos + 1;
  END LOOP;
  --
  -- inverte os dois primeiros digitos
  v_num_sai_char := substr(v_num_sai_char, 2, 1) || substr(v_num_sai_char, 1, 1) ||
                    substr(v_num_sai_char, 3);
  --
  v_num_rand1 := trunc(dbms_random.value(1000, 9999));
  v_num_rand2 := trunc(dbms_random.value(10, 99));
  v_num_rand3 := trunc(dbms_random.value(100, 999));
  --
  -- acrescenta nros randomicos no inicio, meio e fim
  v_num_sai_char := to_char(v_num_rand1) || substr(v_num_sai_char, 1, 2) || to_char(v_num_rand2) ||
                    substr(v_num_sai_char, 3) || to_char(v_num_rand3);
  --
  v_retorno := to_number(v_num_sai_char);
  -- retorno temporario, enquanto nao se aplica em tudo
  --v_retorno := p_numero * 1;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := -99999;
   RETURN v_retorno;
 END num_encode;
 --
 --
 FUNCTION num_decode
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 24/05/2016
  -- DESCRICAO: decodifica campo numerico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_numero IN NUMBER,
  p_chave  IN VARCHAR2
 ) RETURN NUMBER IS
  v_retorno      NUMBER;
  v_numero       NUMBER;
  v_tamanho      NUMBER(10);
  v_num_ent_char VARCHAR2(100);
  v_num_sai_char VARCHAR2(100);
  v_num_ent      NUMBER(5);
  v_num_sai      NUMBER(5);
  v_pos          NUMBER(5);
  v_saida        EXCEPTION;
 BEGIN
  v_retorno := NULL;
  --
  IF p_numero IS NULL OR p_numero = 0 THEN
   v_retorno := p_numero;
   RAISE v_saida;
  END IF;
  --
  IF p_chave <> g_key_num OR TRIM(p_chave) IS NULL THEN
   v_retorno := -99999;
   RAISE v_saida;
  END IF;
  --
  v_num_sai_char := TRIM(to_char(p_numero));
  v_tamanho      := length(v_num_sai_char);
  --
  -- retira nros randomicos do inicio, meio e fim
  -- (4 pos do inicio, 3 do fim e 2 do meio)
  v_num_sai_char := substr(v_num_sai_char, 5, v_tamanho - 7);
  v_num_sai_char := substr(v_num_sai_char, 1, 2) || substr(v_num_sai_char, 5);
  --
  -- desinverte os dois primeiros digitos
  v_num_sai_char := substr(v_num_sai_char, 2, 1) || substr(v_num_sai_char, 1, 1) ||
                    substr(v_num_sai_char, 3);
  --
  -- recalcula o tamanho
  v_tamanho := length(v_num_sai_char);
  --
  -- recupera digitos de acordo com a tabela de transformacao
  v_pos := 1;
  WHILE v_pos <= v_tamanho
  LOOP
   v_num_sai := to_number(substr(v_num_sai_char, v_pos, 1));
   --
   SELECT MAX(num_ent)
     INTO v_num_ent
     FROM TABLE(transf_montar(3, v_tamanho))
    WHERE num_sai = v_num_sai
      AND pos = v_pos;
   --
   IF v_num_sai IS NULL THEN
    v_retorno := -99999;
    RAISE v_saida;
   END IF;
   --
   v_num_ent_char := v_num_ent_char || to_char(v_num_ent);
   v_pos          := v_pos + 1;
  END LOOP;
  --
  -- trata as 2 casas decimais
  v_numero := to_number(v_num_ent_char) / 100;
  --
  v_retorno := v_numero;
  -- retorno temporario, enquanto nao se aplica em tudo
  --v_retorno := p_numero / 1;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := -99999;
   RETURN v_retorno;
 END num_decode;
 --
 FUNCTION extenso_retornar
 (
  p_num       IN NUMBER,
  p_monetario IN VARCHAR2
 ) RETURN CHAR IS
  TYPE tabela IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  --
  extenso  VARCHAR2(500);
  extensao VARCHAR2(5000);
  --
  reg    tabela;
  campo1 VARCHAR2(3);
  campo2 VARCHAR2(3);
  campo3 VARCHAR2(3);
  campo4 VARCHAR2(3);
  var    VARCHAR2(02);
 BEGIN
  /* DE 1 A 99 */
  reg(1) := 'UM';
  reg(2) := 'DOIS';
  reg(3) := 'TRÊS';
  reg(4) := 'QUATRO';
  reg(5) := 'CINCO';
  reg(6) := 'SEIS';
  reg(7) := 'SETE';
  reg(8) := 'OITO';
  reg(9) := 'NOVE';
  reg(10) := 'DEZ';
  reg(11) := 'ONZE';
  reg(12) := 'DOZE';
  reg(13) := 'TREZE';
  reg(14) := 'QUATORZE';
  reg(15) := 'QUINZE';
  reg(16) := 'DEZESSEIS';
  reg(17) := 'DEZESSETE';
  reg(18) := 'DEZOITO';
  reg(19) := 'DEZENOVE';
  reg(20) := 'VINTE';
  reg(21) := 'VINTE E UM';
  reg(22) := 'VINTE E DOIS';
  reg(23) := 'VINTE E TRÊS';
  reg(24) := 'VINTE E QUATRO';
  reg(25) := 'VINTE E CINCO';
  reg(26) := 'VINTE E SEIS';
  reg(27) := 'VINTE E SETE';
  reg(28) := 'VINTE E OITO';
  reg(29) := 'VINTE E NOVE';
  reg(30) := 'TRINTA';
  reg(31) := 'TRINTA E UM';
  reg(32) := 'TRINTA E DOIS';
  reg(33) := 'TRINTA E TRÊS';
  reg(34) := 'TRINTA E QUATRO';
  reg(35) := 'TRINTA E CINCO';
  reg(36) := 'TRINTA E SEIS';
  reg(37) := 'TRINTA E SETE';
  reg(38) := 'TRINTA E OITO';
  reg(39) := 'TRINTA E NOVE';
  reg(40) := 'QUARENTA';
  reg(41) := 'QUARENTA E UM';
  reg(42) := 'QUARENTA E DOIS';
  reg(43) := 'QUARENTA E TRÊS';
  reg(44) := 'QUARENTA E QUATRO';
  reg(45) := 'QUARENTA E CINCO';
  reg(46) := 'QUARENTA E SEIS';
  reg(47) := 'QUARENTA E SETE';
  reg(48) := 'QUARENTA E OITO';
  reg(49) := 'QUARENTA E NOVE';
  reg(50) := 'CINQUENTA';
  reg(51) := 'CINQUENTA E UM';
  reg(52) := 'CINQUENTA E DOIS';
  reg(53) := 'CINQUENTA E TRÊS';
  reg(54) := 'CINQUENTA E QUATRO';
  reg(55) := 'CINQUENTA E CINCO';
  reg(56) := 'CINQUENTA E SEIS';
  reg(57) := 'CINQUENTA E SETE';
  reg(58) := 'CINQUENTA E OITO';
  reg(59) := 'CINQUENTA E NOVE';
  reg(60) := 'SESSENTA';
  reg(61) := 'SESSENTA E UM';
  reg(62) := 'SESSENTA E DOIS';
  reg(63) := 'SESSENTA E TRÊS';
  reg(64) := 'SESSENTA E QUATRO';
  reg(65) := 'SESSENTA E CINCO';
  reg(66) := 'SESSENTA E SEIS';
  reg(67) := 'SESSENTA E SETE';
  reg(68) := 'SESSENTA E OITO';
  reg(69) := 'SESSENTA E NOVE';
  reg(70) := 'SETENTA';
  reg(71) := 'SETENTA E UM';
  reg(72) := 'SETENTA E DOIS';
  reg(73) := 'SETENTA E TRÊS';
  reg(74) := 'SETENTA E QUATRO';
  reg(75) := 'SETENTA E CINCO';
  reg(76) := 'SETENTA E SEIS';
  reg(77) := 'SETENTA E SETE';
  reg(78) := 'SETENTA E OITO';
  reg(79) := 'SETENTA E NOVE';
  reg(80) := 'OITENTA';
  reg(81) := 'OITENTA E UM';
  reg(82) := 'OITENTA E DOIS';
  reg(83) := 'OITENTA E TRÊS';
  reg(84) := 'OITENTA E QUATRO';
  reg(85) := 'OITENTA E CINCO';
  reg(86) := 'OITENTA E SEIS';
  reg(87) := 'OITENTA E SETE';
  reg(88) := 'OITENTA E OITO';
  reg(89) := 'OITENTA E NOVE';
  reg(90) := 'NOVENTA';
  reg(91) := 'NOVENTA E UM';
  reg(92) := 'NOVENTA E DOIS';
  reg(93) := 'NOVENTA E TRÊS';
  reg(94) := 'NOVENTA E QUATRO';
  reg(95) := 'NOVENTA E CINCO';
  reg(96) := 'NOVENTA E SEIS';
  reg(97) := 'NOVENTA E SETE';
  reg(98) := 'NOVENTA E OITO';
  reg(99) := 'NOVENTA E NOVE';
  --
  reg(000) := NULL;
  reg(100) := 'CENTO';
  reg(200) := 'DUZENTOS';
  reg(300) := 'TREZENTOS';
  reg(400) := 'QUATROCENTOS';
  reg(500) := 'QUINHENTOS';
  reg(600) := 'SEISCENTOS';
  reg(700) := 'SETECENTOS';
  reg(800) := 'OITOCENTOS';
  reg(900) := 'NOVECENTOS';
  reg(101) := 'CEM';
  --
  campo1 := substr(ltrim(to_char(p_num, '099999999.99')), 1, 3);
  IF (campo1 <> '000') THEN
   IF (substr(campo1, 1, 3) = '100') THEN
    var := '01';
   ELSE
    var := '00';
   END IF;
  END IF;
  SELECT reg(substr(campo1, 1, 1) || var) ||
         decode(substr(campo1, 1, 1), '0', NULL, decode(substr(campo1, 2, 2), '00', NULL, ' E ')) ||
         reg(substr(campo1, 2, 2)) || decode(campo1, '000', NULL, '001', ' MILHÃO', ' MILHÕES')
    INTO extenso
    FROM dual;
  extensao := rtrim(extenso, ' ');
  --
  campo2 := substr(ltrim(to_char(p_num, '099999999.99')), 4, 3);
  var    := NULL;
  IF (campo2 <> '000') THEN
   IF (substr(campo2, 1, 3) = '100') THEN
    var := '01';
   ELSE
    var := '00';
   END IF;
  END IF;
  SELECT decode(substr(campo1, 1, 3), '000', NULL, decode(substr(campo2, 1, 3), '000', NULL, '* ')) ||
         reg(substr(campo2, 1, 1) || var) ||
         decode(substr(campo2, 1, 1), '0', NULL, decode(substr(campo2, 2, 2), '00', NULL, ' E ')) ||
         reg(substr(campo2, 2, 2)) || decode(campo2, '000', NULL, ' MIL')
    INTO extenso
    FROM dual;
  extensao := rtrim(extensao, ' ') || extenso;
  --
  campo3 := substr(ltrim(to_char(p_num, '099999999.99')), 7, 3);
  var    := NULL;
  IF (campo3 <> '000') THEN
   IF (substr(campo3, 1, 3) = '100') THEN
    var := '01';
   ELSE
    var := '00';
   END IF;
  END IF;
  SELECT decode(campo1,
                '000',
                decode(campo2, '000', NULL, decode(campo3, '000', NULL, '+ ')),
                decode(campo2,
                       '000',
                       decode(campo3, '000', NULL, '+ '),
                       decode(campo3, '000', NULL, '+ '))) || reg(substr(campo3, 1, 1) || var) ||
         decode(substr(campo3, 1, 1), '0', NULL, decode(substr(campo3, 2, 2), '00', NULL, ' E ')) ||
         reg(substr(campo3, 2, 2))
    INTO extenso
    FROM dual;
  extensao := rtrim(extensao, ' ') || extenso;
  --
  IF p_monetario = 'S' THEN
   SELECT decode(campo1,
                 '000',
                 decode(campo2,
                        '000',
                        decode(campo3, '000', NULL, '001', ' REAL', ' REAIS'),
                        decode(campo3, '000', ' REAIS', '001', ' REAL', ' REAIS')),
                 decode(campo2,
                        '000',
                        decode(campo3, '000', ' DE REAIS', '001', ' REAL', ' REAIS'),
                        decode(campo3, '000', ' REAIS', '001', ' REAL', ' REAIS')))
     INTO extenso
     FROM dual;
   extensao := rtrim(extensao, ' ') || extenso;
  END IF;
  --
  IF p_monetario = 'S' THEN
   campo4 := substr(ltrim(to_char(p_num, '099999999.99')), 11, 2);
   SELECT decode(campo4, '00', NULL, decode(trunc(nvl(p_num, 0)), 0, NULL, '- ')) || reg(campo4) ||
          decode(campo4, '00', NULL, '01', ' CENTAVO', ' CENTAVOS')
     INTO extenso
     FROM dual;
   extensao := rtrim(extensao, ' ') || extenso;
  ELSE
   campo4 := substr(ltrim(to_char(p_num, '099999999.99')), 11, 2);
   SELECT decode(campo4, '00', NULL, decode(trunc(nvl(p_num, 0)), 0, NULL, '- ')) || reg(campo4) ||
          decode(campo4, '00', NULL, '01', '', '')
     INTO extenso
     FROM dual;
   extensao := rtrim(extensao, ' ') || extenso;
  END IF;
  --
  --return (extensao);
  IF p_monetario = 'S' THEN
   SELECT decode(nvl(instr(extensao, '-'), 0),
                 0,
                 decode(nvl(instr(extensao, '+'), 0),
                        0,
                        decode(nvl(instr(extensao, '*'), 0), 0, extensao, REPLACE(extensao, '*', ',')),
                        REPLACE(extensao, '+', ',')),
                 REPLACE(extensao, '-', ' E'))
     INTO extensao
     FROM dual;
  ELSE
   SELECT decode(nvl(instr(extensao, '-'), 0),
                 0,
                 decode(nvl(instr(extensao, '+'), 0),
                        0,
                        decode(nvl(instr(extensao, '*'), 0), 0, extensao, REPLACE(extensao, '*', ',')),
                        REPLACE(extensao, '+', ',')),
                 REPLACE(extensao, '-', ' VÍRGULA'))
     INTO extensao
     FROM dual;
  END IF;
  --
  extensao := REPLACE(extensao, '-', ',');
  extensao := REPLACE(extensao, '+', ',');
  extensao := REPLACE(extensao, '*', ',');
  --
  --extensao := extensao || ' ' || rpad(extensao, 5000, '*');
  RETURN(extensao);
 END; --extenso_retornar
 --
 FUNCTION hexa_cor(cor IN VARCHAR2) RETURN VARCHAR2 IS
  hex_color VARCHAR2(7);
 BEGIN
  CASE cor
   WHEN 'kanban-cor-1' THEN
    hex_color := '#b5cec9';
   WHEN 'kanban-cor-2' THEN
    hex_color := '#b6cccf';
   WHEN 'kanban-cor-3' THEN
    hex_color := '#c0ded2';
   WHEN 'kanban-cor-4' THEN
    hex_color := '#ced8cf';
   WHEN 'kanban-cor-5' THEN
    hex_color := '#d8feb4';
   WHEN 'kanban-cor-6' THEN
    hex_color := '#d6e0ea';
   WHEN 'kanban-cor-7' THEN
    hex_color := '#d8dcf8';
   WHEN 'kanban-cor-8' THEN
    hex_color := '#b6c8fe';
   WHEN 'kanban-cor-9' THEN
    hex_color := '#f2fdcc';
   WHEN 'kanban-cor-10' THEN
    hex_color := '#c4eafa';
   WHEN 'kanban-cor-11' THEN
    hex_color := '#e1cdca';
   WHEN 'kanban-cor-12' THEN
    hex_color := '#f8bcf2';
   WHEN 'kanban-cor-13' THEN
    hex_color := '#e8e5bb';
   WHEN 'kanban-cor-14' THEN
    hex_color := '#e8e6d3';
   WHEN 'kanban-cor-15' THEN
    hex_color := '#f9e7d9';
   WHEN 'kanban-cor-16' THEN
    hex_color := '#f2c9cf';
   WHEN 'kanban-cor-17' THEN
    hex_color := '#ffffff';
   ELSE
    hex_color := cor; -- Caso seja um valor hexadecimal já existente
  END CASE;
  RETURN hex_color;
 END; --hexa_cor
 --
 /*FUNCTION entregavel_restrito_validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 26/12/2024
  -- DESCRICAO: Verifica se entregável possui restrição de tipo de produto para uma 
  -- determinada ordem de serviço. A função retorna 1 se o tipo de produto está associado 
  -- à ordem de serviço, 0 caso contrário. 
  -- Se p_tipo_produto_id = nulo, a função verifica se qualquer tipo de produto é permitido
  -- para o tipo de ordem de serviço associado. Caso não haja registros para o tipo_os_id,
  -- significa que não há restrições, e a função retorna 1.
  ------------------------------------------------------------------------------------------
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_produto_id  IN tipo_prod_tipo_os.tipo_produto_id%TYPE DEFAULT NULL
 ) RETURN INTEGER IS
  v_result     INTEGER := 0;
  v_tipo_os_id ordem_servico.tipo_os_id%TYPE;
 BEGIN
  -- Obtém o tipo_os_id da ordem de serviço
  SELECT os.tipo_os_id
    INTO v_tipo_os_id
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
 
  -- Verifica se há restrição para o tipo_os_id e tipo_produto_id
  IF p_tipo_produto_id IS NULL THEN
   -- Caso p_tipo_produto_id seja NULL, verifica apenas o tipo_os_id
   SELECT CASE
           WHEN EXISTS (SELECT 1
                   FROM tipo_prod_tipo_os t
                  WHERE t.tipo_os_id = v_tipo_os_id) THEN
            1
           ELSE
            0
          END
     INTO v_result
     FROM dual;
  ELSE
   -- Caso contrário, verifica o tipo_produto_id específico
   SELECT CASE
           WHEN EXISTS (SELECT 1
                   FROM tipo_prod_tipo_os t
                  WHERE t.tipo_os_id = v_tipo_os_id
                    AND t.tipo_produto_id = p_tipo_produto_id) THEN
            1
           ELSE
            0
          END
     INTO v_result
     FROM dual;
  END IF;
 
  RETURN v_result;
 
 EXCEPTION
  WHEN no_data_found THEN
   RETURN 1; -- Sem restrições
  WHEN OTHERS THEN
   RETURN - 99999; -- Retorna -99999 em caso de erro
 END entregavel_restrito_validar;*/
 --
 FUNCTION entregavel_restrito_validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza            ProcessMind     DATA: 12/26/2024
  -- DESCRICAO: Verifica se entregavel possui restricao de tipo de produto para uma determinada
  -- ordem de serviço.A função retorna 1 se o tipo de produto está associado à 
  -- ordem de serviço, 0 caso contrário. 
  -- Se p_tipo_produto_id = nulo e v_tipoprod_semconfig = N entao a função retorna 1
  ------------------------------------------------------------------------------------------
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_tipo_os_id      IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_produto_id IN tipo_prod_tipo_os.tipo_produto_id%TYPE DEFAULT NULL
 ) RETURN INTEGER IS
  v_result INTEGER := 0;
 BEGIN
  SELECT CASE
          WHEN EXISTS (SELECT 1
                  FROM tipo_prod_tipo_os t
                 WHERE t.tipo_os_id = p_tipo_os_id
                   AND (t.tipo_produto_id = p_tipo_produto_id)) THEN
           1
          ELSE
           0
         END
    INTO v_result
    FROM dual;
  --
  RETURN v_result;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN - 99999; -- Em caso de erro, retorna -99999 como default
 END entregavel_restrito_validar;
 --
END; -- UTIL_pkg

/
