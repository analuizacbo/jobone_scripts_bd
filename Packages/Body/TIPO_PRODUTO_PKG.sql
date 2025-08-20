--------------------------------------------------------
--  DDL for Package Body TIPO_PRODUTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_PRODUTO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Inclusão de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/08/2008  Implementacao de variacoes do tipo de produto.
  -- Silvia            25/11/2008  Novo parametro classe_produto_id.
  -- Silvia            06/12/2010  Novo parametro tempo_exec_info.
  -- Silvia            01/12/2011  Aceita tb ponto-e-virtula em p_variacoes (troca autom).
  -- Silvia            24/11/2014  Aceita virgula no nome. O ponto-e-virgula passou a ser
  --                               o separador usado em variacoes no lugar da virgula.
  -- Silvia            20/07/2016  Novo parametro categoria.
  -- Silvia            27/06/2017  Novos parametros flag_midia_online, flag_midia_offline.
  -- Silvia            17/08/2021  Novo parametro flag_cliente
  -- Ana Luiza         19/05/2023  Remoção das colunas custo interno min, med e max.
  -- Ana Luiza         29/06/2023  Adição da coluna unidade_freq e custo preco para chamada
  --                               de subrotina.
  -- Ana Luiza         25/11/2024  Substituicao categoria por categoria_id na tab tipo_produto            
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  --p_classe_produto_id  IN tipo_produto.classe_produto_id%TYPE,   
  p_nome            IN tipo_produto.nome%TYPE,
  p_categoria_id    IN tipo_produto.categoria_id%TYPE,
  p_cod_ext_produto IN tipo_produto.cod_ext_produto%TYPE,
  p_variacoes       IN VARCHAR2,
  p_vetor_tipo_os   IN VARCHAR2,
  p_tempo_exec_info IN VARCHAR2,
  p_flag_ativo      IN tipo_produto.flag_ativo%TYPE,
  --p_flag_midia_online  IN tipo_produto.flag_midia_online%TYPE, 
  --p_flag_midia_offline IN tipo_produto.flag_midia_offline%TYPE, 
  p_flag_tarefa IN tipo_produto.flag_tarefa%TYPE,
  --p_flag_cliente       IN tipo_produto.flag_cliente%TYPE,      
  p_unidade_freq    IN tipo_produto.unidade_freq%TYPE,
  p_vetor_preco_id  IN VARCHAR2,
  p_custo           IN VARCHAR2,
  p_preco           IN VARCHAR2,
  p_tipo_produto_id OUT tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_tipo_produto_id tipo_produto.tipo_produto_id%TYPE;
  v_tempo_exec_info tipo_produto.tempo_exec_info%TYPE;
  v_variacoes       tipo_produto.variacoes%TYPE;
  v_vetor_tipo_os   VARCHAR2(500);
  v_tipo_os_id      tipo_os.tipo_os_id%TYPE;
  v_delimitador     CHAR(1);
  v_nome_var        VARCHAR2(100);
  v_nome_aux        VARCHAR2(100);
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt              := 0;
  p_tipo_produto_id := 0;
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
  IF p_flag_commit = 'S'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_PRODUTO_C', NULL, NULL, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(p_nome, '|') > 0 OR instr(p_nome, ';') > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode conter pipe ou ponto-e-vírgula.';
   RAISE v_exception;
  END IF;
  --ALCBO_251124
  SELECT MAX(categoria_id)
    INTO v_qt
    FROM categoria
   WHERE categoria_id = p_categoria_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de categoria não existe (' || p_categoria_id || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_variacoes) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As variações do nome são limitadas em 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF instr(p_variacoes, '|') > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As variações do nome não podem conter pipe.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_tempo_exec_info) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tempo médio de execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  /*IF flag_validar(p_flag_midia_online) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag mídia online inválido.';
   RAISE v_exception;
  END IF;*/
  --
  /*IF flag_validar(p_flag_midia_offline) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag mídia offline inválido.';
   RAISE v_exception;
  END IF;*/
  --
  IF flag_validar(p_flag_tarefa) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tarefa inválido.';
   RAISE v_exception;
  END IF;
  --
  /*IF flag_validar(p_flag_cliente) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag cliente inválido.';
   RAISE v_exception;
  END IF;*/
  --
  v_tempo_exec_info := round(numero_converter(p_tempo_exec_info), 2);
  --
  IF v_tempo_exec_info < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tempo médio de execução inválido.';
   RAISE v_exception;
  END IF;
  --
  /*IF nvl(p_classe_produto_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM classe_produto
    WHERE classe_produto_id = p_classe_produto_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa classe de produto não existe.';
    RAISE v_exception;
   END IF;
  END IF;*/
  --
  IF TRIM(p_unidade_freq) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da unidade de frequência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_custo IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do custo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_custo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de custo inválido (' || p_custo || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_preco IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_preco) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de preço inválido (' || p_preco || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome))
     AND empresa_id = p_empresa_id;
  --ALCBO_290623
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de produto já existe.';
   RAISE v_exception;
  END IF;
  --ALCBO_290623
  --Perguntar Silvia como valida no dicionario
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM dicion_emp
     WHERE empresa_id = p_empresa_id
       AND dicion_emp_id = p_dicion_emp_id;
  --
    IF v_qt = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Esse atributo do dicionário não
                     existe ou não pertence a essa empresa.';
       RAISE v_exception;
    END IF;
    */
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_produto.nextval
    INTO v_tipo_produto_id
    FROM dual;
  --ALCBO_290623
  INSERT INTO tipo_produto
   (tipo_produto_id,
    empresa_id,
    --classe_produto_id,
    nome,
    variacoes,
    tempo_exec_info,
    flag_ativo,
    flag_sistema,
    cod_ext_produto,
    categoria_id,
    --flag_midia_online,
    --flag_midia_offline,
    flag_tarefa,
    --flag_cliente,
    unidade_freq)
  VALUES
   (v_tipo_produto_id,
    p_empresa_id,
    --zvl(p_classe_produto_id, NULL),
    TRIM(p_nome),
    TRIM(p_variacoes),
    v_tempo_exec_info,
    p_flag_ativo,
    'N',
    TRIM(p_cod_ext_produto),
    p_categoria_id,
    --p_flag_midia_online,
    --p_flag_midia_offline,
    p_flag_tarefa,
    --p_flag_cliente,
    p_unidade_freq);
  --
  ------------------------------------------------------------
  -- tratamento das variacoes de nomes
  ------------------------------------------------------------
  v_variacoes   := TRIM(p_variacoes);
  v_delimitador := ';';
  --
  WHILE nvl(length(rtrim(v_variacoes)), 0) > 0
  LOOP
   v_nome_var := prox_valor_retornar(v_variacoes, v_delimitador);
   v_nome_var := acento_retirar(TRIM(v_nome_var));
   --
   IF length(v_nome_var) > 60
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tamanho de uma única variação não pode exceder ' || '60 caracteres (' ||
                  v_nome_var || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_nome_var IS NOT NULL
   THEN
    SELECT MAX(nome)
      INTO v_nome_aux
      FROM tipo_produto
     WHERE tipo_produto_id <> p_tipo_produto_id
       AND acento_retirar(nome) = v_nome_var
       AND empresa_id = p_empresa_id;
    --
    IF v_nome_aux IS NOT NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa variação (' || v_nome_var || ') já está definida como um tipo de produto.';
     RAISE v_exception;
    END IF;
    --
    SELECT MAX(tp.nome)
      INTO v_nome_aux
      FROM tipo_produto_var tv,
           tipo_produto     tp
     WHERE tp.tipo_produto_id = tv.tipo_produto_id
       AND acento_retirar(tv.nome) = v_nome_var
       AND tp.empresa_id = p_empresa_id;
    --
    IF v_nome_aux IS NOT NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa variação (' || upper(v_nome_var) ||
                   ') já está associada a um tipo de produto (' || v_nome_aux || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO tipo_produto_var
     (tipo_produto_id,
      nome)
    VALUES
     (v_tipo_produto_id,
      v_nome_var);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo de OS
  ------------------------------------------------------------
  v_vetor_tipo_os := p_vetor_tipo_os;
  v_delimitador   := '|';
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_os)), 0) > 0
  LOOP
   v_tipo_os_id := to_number(prox_valor_retornar(v_vetor_tipo_os, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os
    WHERE tipo_os_id = v_tipo_os_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Tipo de Workflow não existe (' || to_char(v_tipo_os_id) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO tipo_prod_tipo_os
    (tipo_produto_id,
     tipo_os_id)
   VALUES
    (v_tipo_produto_id,
     v_tipo_os_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('TIPO_PRODUTO_ADICIONAR',
                           p_empresa_id,
                           v_tipo_produto_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ----------------------------------------------------------------------------------------
  -- Adicao subrotina sem commit, vincula tabela de preço à tipo_produto_preco
  ----------------------------------------------------------------------------------------
  preco_pkg.tipo_produto_vincular(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_tipo_produto_id,
                                  p_vetor_preco_id,
                                  p_custo,
                                  p_preco,
                                  p_erro_cod,
                                  p_erro_msg);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(v_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_produto_id,
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
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_tipo_produto_id := v_tipo_produto_id;
  p_erro_cod        := '00000';
  p_erro_msg        := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Atualização de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/08/2008  Implementacao de variacoes do tipo de produto.
  -- Silvia            25/11/2008  Novo parametro classe_produto_id.
  -- Silvia            06/12/2010  Novo parametro tempo_exec_info.
  -- Silvia            01/12/2011  Aceita tb ponto-e-virtula em p_variacoes (troca autom).
  -- Silvia            24/11/2014  Aceita virgula no nome. O ponto-e-virgula passou a ser
  --                               o separador usado em variacoes no lugar da virgula.
  -- Silvia            20/07/2016  Novo parametro categoria.
  -- Silvia            27/06/2017  Novos parametros flag_midia_online, flag_midia_offline.
  -- Silvia            03/08/2021  Novo parametro flag_tarefa
  -- Silvia            17/08/2021  Novo parametro flag_cliente
  -- Ana Luiza         19/05/2023  Remoção das colunas custo interno min, med e max.
  -- Ana Luiza         29/06/2023  Adição da coluna unidade_freq.
  -- Ana Luiza         14/07/2023  Remoção parametros p_custo_interno_min, max e med.
  -- Ana Luiza         25/11/2024  Substituicao categoria por categoria_id na tab tipo_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_nome              IN tipo_produto.nome%TYPE,
  p_categoria_id      IN tipo_produto.categoria_id%TYPE,
  p_cod_ext_produto   IN tipo_produto.cod_ext_produto%TYPE,
  p_variacoes         IN VARCHAR2,
  p_vetor_tipo_os     IN VARCHAR2,
  p_tempo_exec_info   IN VARCHAR2,
  p_flag_ativo        IN tipo_produto.flag_ativo%TYPE,
  p_flag_tarefa       IN tipo_produto.flag_tarefa%TYPE,
  p_unidade_freq      IN tipo_produto.unidade_freq%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_tempo_exec_info     tipo_produto.tempo_exec_info%TYPE;
  v_flag_sistema        tipo_produto.flag_sistema%TYPE;
  v_variacoes           tipo_produto.variacoes%TYPE;
  v_cod_ext_produto_ant tipo_produto.cod_ext_produto%TYPE;
  v_nome_ant            tipo_produto.nome%TYPE;
  v_vetor_tipo_os       VARCHAR2(500);
  v_tipo_os_id          tipo_os.tipo_os_id%TYPE;
  v_delimitador         CHAR(1);
  v_nome_var            VARCHAR2(100);
  v_nome_aux            VARCHAR2(100);
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_PRODUTO_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_sistema,
         cod_ext_produto,
         nome
    INTO v_flag_sistema,
         v_cod_ext_produto_ant,
         v_nome_ant
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  IF v_flag_sistema = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser alterado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(p_nome, '|') > 0 OR instr(p_nome, ';') > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode conter pipe ou ponto-e-vírgula.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(categoria_id)
    INTO v_qt
    FROM categoria
   WHERE categoria_id = p_categoria_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de categoria não existe (' || p_categoria_id || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_variacoes) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As variações do nome são limitadas em 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF instr(p_variacoes, '|') > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As variações do nome não podem conter pipe.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_tempo_exec_info) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tempo médio de execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tarefa) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tarefa inválido.';
   RAISE v_exception;
  END IF;
  --
  v_tempo_exec_info := round(numero_converter(p_tempo_exec_info), 2);
  --
  IF v_tempo_exec_info < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tempo médio de execução inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id <> p_tipo_produto_id
     AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de produto já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(p_tipo_produto_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_190523
  UPDATE tipo_produto
     SET nome            = TRIM(p_nome),
         variacoes       = TRIM(p_variacoes),
         flag_ativo      = p_flag_ativo,
         tempo_exec_info = v_tempo_exec_info,
         cod_ext_produto = TRIM(p_cod_ext_produto),
         categoria_id    = p_categoria_id,
         flag_tarefa     = p_flag_tarefa,
         unidade_freq    = p_unidade_freq
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  ------------------------------------------------------------
  -- tratamento das variacoes de nomes
  ------------------------------------------------------------
  DELETE FROM tipo_produto_var
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  v_variacoes   := TRIM(p_variacoes);
  v_delimitador := ';';
  --
  WHILE nvl(length(rtrim(v_variacoes)), 0) > 0
  LOOP
   v_nome_var := prox_valor_retornar(v_variacoes, v_delimitador);
   v_nome_var := acento_retirar(TRIM(v_nome_var));
   --
   IF length(v_nome_var) > 60
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tamanho de uma única variação não pode exceder ' || '60 caracteres (' ||
                  v_nome_var || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_nome_var IS NOT NULL
   THEN
    SELECT MAX(nome)
      INTO v_nome_aux
      FROM tipo_produto
     WHERE tipo_produto_id <> p_tipo_produto_id
       AND acento_retirar(nome) = v_nome_var
       AND empresa_id = p_empresa_id;
    --
    IF v_nome_aux IS NOT NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa variação (' || v_nome_var || ') já está definida como um tipo de produto.';
     RAISE v_exception;
    END IF;
    --
    SELECT MAX(tp.nome)
      INTO v_nome_aux
      FROM tipo_produto_var tv,
           tipo_produto     tp
     WHERE tp.tipo_produto_id = tv.tipo_produto_id
       AND acento_retirar(tv.nome) = v_nome_var
       AND tp.empresa_id = p_empresa_id;
    --
    IF v_nome_aux IS NOT NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa variação (' || upper(v_nome_var) ||
                   ') já está associada a um tipo de produto (' || v_nome_aux || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO tipo_produto_var
     (tipo_produto_id,
      nome)
    VALUES
     (p_tipo_produto_id,
      v_nome_var);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo de OS
  ------------------------------------------------------------
  DELETE FROM tipo_prod_tipo_os
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  v_vetor_tipo_os := p_vetor_tipo_os;
  v_delimitador   := '|';
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_os)), 0) > 0
  LOOP
   v_tipo_os_id := to_number(prox_valor_retornar(v_vetor_tipo_os, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os
    WHERE tipo_os_id = v_tipo_os_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Tipo de Workflow não existe (' || to_char(v_tipo_os_id) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO tipo_prod_tipo_os
    (tipo_produto_id,
     tipo_os_id)
   VALUES
    (p_tipo_produto_id,
     v_tipo_os_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('TIPO_PRODUTO_ATUALIZAR',
                           p_empresa_id,
                           p_tipo_produto_id,
                           v_cod_ext_produto_ant || ',' || v_nome_ant,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(p_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_produto_id,
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
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Exclusão de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/08/2008  Implementacao de variacoes do tipo de produto.
  -- Silvia            06/12/2010  Consistencia de tipo_produto_os.
  -- Ana Luiza         26/04/2024  Exclusao tipo produto preco
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome           tipo_produto.nome%TYPE;
  v_flag_sistema   tipo_produto.flag_sistema%TYPE;
  v_xml_atual      CLOB;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_PRODUTO_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE tipo_produto_id = p_tipo_produto_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto está sendo referenciado por algum item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tipo_produto  ot,
         job_tipo_produto jt
   WHERE jt.tipo_produto_id = p_tipo_produto_id
     AND jt.job_tipo_produto_id = ot.job_tipo_produto_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto está sendo referenciado por Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_tipo_produto tt,
         job_tipo_produto    jt
   WHERE jt.tipo_produto_id = p_tipo_produto_id
     AND jt.job_tipo_produto_id = tt.job_tipo_produto_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto está sendo referenciado por Task.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_tipo_produto jt
   WHERE jt.tipo_produto_id = p_tipo_produto_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto está sendo referenciado por ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM desp_realiz
   WHERE tipo_produto_id = p_tipo_produto_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto está sendo referenciado por despesa de adiantamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         flag_sistema
    INTO v_nome,
         v_flag_sistema
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  IF v_flag_sistema = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser excluído.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('TIPO_PRODUTO_EXCLUIR',
                           p_empresa_id,
                           p_tipo_produto_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(p_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM metadado
   WHERE objeto_id = p_tipo_produto_id
     AND tipo_objeto = 'TIPO_PRODUTO'
     AND empresa_id = p_empresa_id;
  DELETE FROM tipo_prod_tipo_os
   WHERE tipo_produto_id = p_tipo_produto_id;
  DELETE FROM tipo_produto_var
   WHERE tipo_produto_id = p_tipo_produto_id;
  --ALCBO_260424
  DELETE FROM tipo_produto_preco
   WHERE tipo_produto_id = p_tipo_produto_id;
  DELETE FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_produto_id,
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
 END; -- excluir
 --
 --
 PROCEDURE substituir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 07/08/2008
  -- DESCRICAO: Substitui um determinado tipo_produto_id usado nos itens, pelo novo
  --   tipo_produto_id informado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/08/2008  Implementacao de variacoes do tipo de produto.
  -- Silvia            17/05/2023  Verificacao de chave alternada em job_tipo_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tipo_produto_id_old IN tipo_produto.tipo_produto_id%TYPE,
  p_tipo_produto_id_new IN tipo_produto.tipo_produto_id%TYPE,
  p_flag_concat_complem IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome_old       tipo_produto.nome%TYPE;
  v_nome_new       tipo_produto.nome%TYPE;
  v_flag_sistema   tipo_produto.flag_sistema%TYPE;
  v_complemento    VARCHAR2(1000);
  v_xml_atual      CLOB;
  v_job_id         job.job_id%TYPE;
  v_num_job        job.numero%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  --
  CURSOR c_item IS
   SELECT item_id,
          complemento
     FROM item
    WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_PRODUTO_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id_old
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id_new
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse novo tipo de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_concat_complem) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF p_tipo_produto_id_old = p_tipo_produto_id_new
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A substituição não pode ser feita para o mesmo tipo de produto.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         flag_sistema
    INTO v_nome_old,
         v_flag_sistema
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
  IF v_flag_sistema = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser excluído.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         flag_sistema
    INTO v_nome_new,
         v_flag_sistema
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id_new;
  --
  IF v_flag_sistema = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser usado.';
   RAISE v_exception;
  END IF;
  --
  -- verifica possivel violacao da chave alternada na tabela JOB_TIPO_PRODUTO
  -- (job_id + tipo_produto_id + complemento) resultante da substituicao
  SELECT MAX(j1.job_id)
    INTO v_job_id
    FROM job_tipo_produto j1,
         job_tipo_produto j2
   WHERE j1.tipo_produto_id = p_tipo_produto_id_old
     AND j2.tipo_produto_id = p_tipo_produto_id_new
     AND j1.job_id = j2.job_id
     AND nvl(TRIM(j1.complemento), 'ZZZZZ') = nvl(TRIM(j2.complemento), 'ZZZZZ');
  --
  IF v_job_id IS NOT NULL
  THEN
   SELECT numero
     INTO v_num_job
     FROM job
    WHERE job_id = v_job_id;
   --
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esses dois tipos de produto ' ||
                 ' que impedem a substituição (' || v_num_job || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(p_tipo_produto_id_old, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_item IN c_item
  LOOP
   IF p_flag_concat_complem = 'S'
   THEN
    v_complemento := TRIM(v_nome_old || ' ' || r_item.complemento);
    --
    IF length(v_complemento) > 500
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A inclusão do tipo anterior no complemento do item, ' ||
                   'resulta num texto com mais de 500 caracteres para alguns itens.';
     RAISE v_exception;
    END IF;
   ELSE
    v_complemento := r_item.complemento;
   END IF;
   --
   UPDATE item
      SET tipo_produto_id = p_tipo_produto_id_new,
          complemento     = v_complemento
    WHERE item_id = r_item.item_id;
  END LOOP;
  --
  -- troca os tipos associados ao job via OS.
  UPDATE job_tipo_produto
     SET tipo_produto_id = p_tipo_produto_id_new
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
  UPDATE item_carta
     SET tipo_produto_id = p_tipo_produto_id_new
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
  UPDATE item_nota
     SET tipo_produto_id = p_tipo_produto_id_new
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
  DELETE FROM metadado
   WHERE objeto_id = p_tipo_produto_id_old
     AND tipo_objeto = 'TIPO_PRODUTO'
     AND empresa_id = p_empresa_id;
  DELETE FROM tipo_prod_tipo_os
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  DELETE FROM tipo_produto_var
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  DELETE FROM tipo_produto_preco
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  DELETE FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id_old;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_old;
  v_compl_histor   := 'Substituído por: ' || v_nome_new;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_produto_id_old,
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
 END; -- substituir
 --
 --
 PROCEDURE texto_tratar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 07/08/2008
  -- DESCRICAO: Trata o texto passado no parametro, separando o tipo de produto
  --  que deveria aparecer no começo, do restante do texto. Nos parametros de output,
  --  retorna o tipo_produto_id encontrado e o complemento do texto sem o tipo de produto.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2012  Ajuste no retorno do complemento.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_texto             IN VARCHAR2,
  p_tipo_produto_id   OUT tipo_produto.tipo_produto_id%TYPE,
  p_complemento       OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_pos               INTEGER;
  v_exception         EXCEPTION;
  v_tipo_produto_id   INTEGER;
  v_texto             VARCHAR2(4000);
  v_caracter_excluido CHAR(1);
  v_cod_tipo_produto  tipo_produto.codigo%TYPE;
  --
 BEGIN
  p_tipo_produto_id := 0;
  p_complemento     := '';
  --
  p_tipo_produto_id := id_retornar(p_empresa_id, p_texto);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo_produto_id não existe (' || to_char(p_tipo_produto_id) || '-' ||
                 p_texto || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT TRIM(codigo)
    INTO v_cod_tipo_produto
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  -- a logica abaixo repete o conteudo da funcao "id_retornar"
  -- apenas para pegar a variavel "v_pos"
  --
  IF v_cod_tipo_produto <> 'ND' OR v_cod_tipo_produto IS NULL
  THEN
   v_tipo_produto_id   := 0;
   v_caracter_excluido := ' ';
   --
   -- pega apenas os primeiros 60 caracteres
   v_texto := substr(TRIM(p_texto), 1, 60);
   --
   -- retira a acentuacao
   v_texto := acento_retirar(v_texto);
   --
   -- vai retirando os caracteres da direita para a esquerda ate achar.
   -- se nao achar nada, retorna 0.
   WHILE v_texto IS NOT NULL AND v_tipo_produto_id = 0
   LOOP
    -- testa se o caracter excluido resultou em corte de palavra
    IF TRIM(v_caracter_excluido) IS NULL OR v_caracter_excluido IN (',', '.', ';', ':', '?', ' ')
    THEN
     --
     -- tenta achar o tipo de produto pelo nome
     SELECT nvl(MAX(tipo_produto_id), 0)
       INTO v_tipo_produto_id
       FROM tipo_produto
      WHERE acento_retirar(nome) = v_texto
        AND empresa_id = p_empresa_id;
     --
     IF v_tipo_produto_id = 0
     THEN
      -- tenta achar o tipo de produto pelas variacoes.
      -- o campo "nome" da tabela tipo_produto_var ja
      -- esta sem acentuacao.
      SELECT nvl(MAX(tv.tipo_produto_id), 0)
        INTO v_tipo_produto_id
        FROM tipo_produto_var tv,
             tipo_produto     tp
       WHERE tv.nome = v_texto
         AND tv.tipo_produto_id = tp.tipo_produto_id
         AND tp.empresa_id = p_empresa_id;
     END IF;
     --
     IF v_tipo_produto_id > 0
     THEN
      -- guarda o tamanho do tipo de produto encontrado
      v_pos := length(v_texto);
     END IF;
    END IF;
    --
    -- guarda o caracter que vai ser descartado
    v_caracter_excluido := substr(v_texto, length(v_texto), 1);
    --
    -- retira um caracter da descricao
    v_texto := substr(v_texto, 1, length(v_texto) - 1);
   END LOOP;
  END IF;
  --
  --
  IF v_cod_tipo_produto = 'ND'
  THEN
   -- nao achou o tipo de produto no comeco do texto.
   -- retorna tudo como complemento.
   p_complemento := TRIM(p_texto);
  ELSE
   -- achou o tipo de produto no comeco.
   -- Retira o tipo de produto e retorna o restante como
   -- complemento.
   p_complemento := TRIM(substr(TRIM(p_texto), v_pos + 1));
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
 END; -- texto_tratar
 --
 --
 PROCEDURE categoria_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza         ProcessMind     DATA: 21/11/2024
  -- DESCRICAO: Inclusão de categoria de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         25/11/2024  Adicao de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_classe_produto_id IN NUMBER,
  p_descricao         IN VARCHAR2,
  p_cod_ext           IN VARCHAR2,
  p_cod_acao_os       IN VARCHAR2,
  p_tipo_entregavel   IN VARCHAR2,
  p_flag_tp_midia_on  IN VARCHAR2,
  p_flag_tp_midia_off IN VARCHAR2,
  p_flag_entregue_cli IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_categoria_id      OUT NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_categoria_id categoria.categoria_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAT_TP_PRODUTO', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_ext) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código externo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_acao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_entregavel) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de entregável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tp_midia_on) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Mídia on inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tp_midia_off) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Mídia off inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_entregue_cli) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag cliente inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM categoria
   WHERE TRIM(descricao) = TRIM(p_descricao)
     AND empresa_id = p_empresa_id
     AND categoria_id <> p_categoria_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de categoria já existe.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_categoria.nextval
    INTO v_categoria_id
    FROM dual;
  --
  INSERT INTO categoria
   (categoria_id,
    classe_produto_id,
    cod_acao_os,
    cod_ext,
    descricao,
    empresa_id,
    flag_ativo,
    flag_entregue_cli,
    tipo_entregavel,
    flag_tp_midia_on,
    flag_tp_midia_off)
  VALUES
   (v_categoria_id,
    TRIM(p_classe_produto_id),
    TRIM(p_cod_acao_os),
    TRIM(p_cod_ext),
    TRIM(p_descricao),
    TRIM(p_empresa_id),
    'S',
    TRIM(p_flag_entregue_cli),
    TRIM(p_tipo_entregavel),
    TRIM(p_flag_tp_midia_on),
    TRIM(p_flag_tp_midia_off));
  --
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_categoria_id := v_categoria_id;
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
 END categoria_adicionar;
 --
 --
 PROCEDURE categoria_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza         ProcessMind     DATA: 21/11/2024
  -- DESCRICAO: Alteração de categoria de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         25/11/2024  Adicao de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_categoria_id      IN NUMBER,
  p_classe_produto_id NUMBER,
  p_flag_ativo        IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_cod_ext           IN VARCHAR2,
  p_cod_acao_os       IN VARCHAR2,
  p_tipo_entregavel   IN VARCHAR2,
  p_flag_tp_midia_on  IN VARCHAR2,
  p_flag_tp_midia_off IN VARCHAR2,
  p_flag_entregue_cli IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_categoria_id categoria.categoria_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAT_TP_PRODUTO', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM categoria
   WHERE categoria_id = p_categoria_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse categoria não existe.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_ext) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código externo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_acao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_entregavel) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de entregável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tp_midia_on) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Mídia on inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tp_midia_off) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Mídia off inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_entregue_cli) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag cliente inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM categoria
   WHERE TRIM(descricao) = TRIM(p_descricao)
     AND empresa_id = p_empresa_id
     AND categoria_id <> p_categoria_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de categoria já existe.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE categoria
     SET flag_ativo        = p_flag_ativo,
         descricao         = TRIM(p_descricao),
         cod_ext           = TRIM(p_cod_ext),
         cod_acao_os       = TRIM(p_cod_acao_os),
         flag_tp_midia_on  = TRIM(p_flag_tp_midia_on),
         flag_tp_midia_off = TRIM(p_flag_tp_midia_off),
         flag_entregue_cli = TRIM(p_flag_entregue_cli),
         classe_produto_id = TRIM(p_classe_produto_id),
         tipo_entregavel   = TRIM(p_tipo_entregavel)
   WHERE categoria_id = p_categoria_id;
  --
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
 END categoria_atualizar;
 --
 --
 PROCEDURE categoria_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza         ProcessMind     DATA: 21/11/2024
  -- DESCRICAO: Exclusão de categoria de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         25/11/2024  Adicao de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_categoria_id      IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_categoria_id categoria.categoria_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAT_TP_PRODUTO', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM categoria
   WHERE categoria_id = p_categoria_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa categoria não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE categoria_id = p_categoria_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem tipos de produtos associados a essa categoria.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_produto
   WHERE categoria_id = p_categoria_id;
  DELETE FROM categoria
   WHERE categoria_id = p_categoria_id;
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
 END categoria_excluir;
 --
 --
 PROCEDURE tempo_gasto_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/12/2010
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a calcular o tempo
  --  medio gasto na execucao dos tipos de produtos, com base nas horas apontadas em OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_erro_cod        VARCHAR2(20);
  v_erro_msg        VARCHAR2(200);
  v_tempo_tot_gasto NUMBER(10, 2);
  v_tempo_gasto     NUMBER(10, 2);
  --
  CURSOR c_tp IS
   SELECT tipo_produto_id
     FROM tipo_produto;
  --
 BEGIN
  v_qt := 0;
  --
  FOR r_tp IN c_tp
  LOOP
   SELECT COUNT(*),
          nvl(SUM(ordem_servico_pkg.tempo_exec_gasto_retornar(os.ordem_servico_id,
                                                              jo.tipo_produto_id)),
              0)
     INTO v_qt,
          v_tempo_tot_gasto
     FROM job_tipo_produto jo,
          os_tipo_produto  os
    WHERE jo.tipo_produto_id = r_tp.tipo_produto_id
      AND jo.job_tipo_produto_id = os.job_tipo_produto_id;
   --
   v_tempo_gasto := 0;
   --
   IF v_qt > 0
   THEN
    v_tempo_gasto := round(v_tempo_tot_gasto / v_qt, 2);
   END IF;
   --
   UPDATE tipo_produto
      SET tempo_exec_calc = v_tempo_gasto
    WHERE tipo_produto_id = r_tp.tipo_produto_id;
  END LOOP;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'tipo_produto_pkg.tempo_gasto_calcular',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   ROLLBACK;
   v_erro_cod := SQLCODE;
   v_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'tipo_produto_pkg.tempo_gasto_calcular',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END; -- tempo_gasto_calcular
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 24/01/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de produto para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         19/05/2023  Remoção das colunas relacionadas à custo
  -- Ana Luiza         09/04/2025  Alterado para pegar a atributos da categoria
  ------------------------------------------------------------------------------------------
 (
  p_tipo_produto_id IN tipo_produto.tipo_produto_id%TYPE,
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
  v_xml_tipo_produto xmltype;
  v_xml_tab_preco    xmltype;
  --
  CURSOR c_to IS
   SELECT ti.nome,
          ti.codigo
     FROM tipo_prod_tipo_os tp,
          tipo_os           ti
    WHERE tp.tipo_produto_id = p_tipo_produto_id
      AND tp.tipo_os_id = ti.tipo_os_id;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tipo_produto_id", ti.tipo_produto_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("variacoes", ti.variacoes),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("midia_online", ca.flag_tp_midia_on), --ALCBO_090425
                   xmlelement("midia_offline", ca.flag_tp_midia_off), --ALCBO_090425
                   xmlelement("do_sistema", ti.flag_sistema),
                   xmlelement("cod_ext_produto", ti.cod_ext_produto),
                   xmlelement("categoria", ca.descricao),
                   xmlelement("cod_classe", cp.cod_classe),
                   xmlelement("sub_classe", cp.sub_classe),
                   xmlelement("nome_classe", cp.nome_classe),
                   xmlelement("tempo_exec_info", numero_mostrar(ti.tempo_exec_info, 2, 'N')),
                   xmlelement("uso_em_tarefa", ti.flag_tarefa),
                   xmlelement("uso_por_cliente", ca.flag_entregue_cli)) --ALCBO_090425
    INTO v_xml_tipo_produto
    FROM tipo_produto   ti,
         classe_produto cp,
         categoria      ca
   WHERE ti.tipo_produto_id = p_tipo_produto_id
     AND ca.classe_produto_id = cp.classe_produto_id(+)
     AND ti.categoria_id = ca.categoria_id(+);
  --
  SELECT xmlagg(xmlelement("rate_card",
                           xmlelement("usu_ult_alt", sub.apelido),
                           xmlelement("data_ult_alt", data_hora_mostrar(sub.data_ult_alt)),
                           xmlelement("nome", sub.nome)))
    INTO v_xml_tab_preco
    FROM (SELECT DISTINCT ti.tipo_produto_id,
                          pr.nome,
                          pe.apelido,
                          pr.data_ult_alt
            FROM tipo_produto ti
            LEFT JOIN tipo_produto_preco tpp
              ON tpp.tipo_produto_id = ti.tipo_produto_id
            LEFT JOIN tab_preco pr
              ON tpp.preco_id = pr.preco_id
            LEFT JOIN pessoa pe
              ON pr.usu_alt_id = pe.usuario_id
           WHERE ti.tipo_produto_id = p_tipo_produto_id) sub;
  --
  FOR r_to IN c_to
  LOOP
   SELECT xmlconcat(xmlelement("tipo_os", r_to.nome))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("uso_restrito_em", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  -- junta tudo debaixo de "tipo_produto"
  SELECT xmlagg(xmlelement("tipo_produto", v_xml_tipo_produto, v_xml_aux1, v_xml_tab_preco))
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
 FUNCTION id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/08/2008
  -- DESCRICAO: verifica se o texto passado pelo parametro, corresponde a algum tipo de
  --   produto ja cadastrado, retornando o tipo_produto_id.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_texto      IN VARCHAR
 ) RETURN INTEGER AS
  v_qt                INTEGER;
  v_tipo_produto_id   INTEGER;
  v_texto             VARCHAR2(4000);
  v_caracter_excluido CHAR(1);
  --
 BEGIN
  --
  v_tipo_produto_id   := 0;
  v_caracter_excluido := ' ';
  --
  -- pega apenas os primeiros 60 caracteres
  v_texto := substr(TRIM(p_texto), 1, 60);
  --
  -- retira a acentuacao
  v_texto := acento_retirar(v_texto);
  --
  -- vai retirando os caracteres da direita para a esquerda ate achar.
  -- se nao achar nada, retorna 0.
  WHILE v_texto IS NOT NULL AND v_tipo_produto_id = 0
  LOOP
   -- testa se o caracter excluido resultou em corte de palavra
   IF TRIM(v_caracter_excluido) IS NULL OR v_caracter_excluido IN (',', '.', ';', ':', '?', ' ')
   THEN
    --
    -- tenta achar o tipo de produto pelo nome
    SELECT nvl(MAX(tipo_produto_id), 0)
      INTO v_tipo_produto_id
      FROM tipo_produto
     WHERE acento_retirar(nome) = v_texto
       AND empresa_id = p_empresa_id;
    --
    IF v_tipo_produto_id = 0
    THEN
     -- tenta achar o tipo de produto pelas variacoes.
     -- o campo "nome" da tabela tipo_produto_var ja
     -- esta sem acentuacao.
     SELECT nvl(MAX(tv.tipo_produto_id), 0)
       INTO v_tipo_produto_id
       FROM tipo_produto_var tv,
            tipo_produto     tp
      WHERE tv.nome = v_texto
        AND tv.tipo_produto_id = tp.tipo_produto_id
        AND tp.empresa_id = p_empresa_id;
    END IF;
   END IF;
   --
   -- guarda o caracter que vai ser descartado
   v_caracter_excluido := substr(v_texto, length(v_texto), 1);
   --
   -- retira um caracter da descricao
   v_texto := substr(v_texto, 1, length(v_texto) - 1);
  END LOOP;
  --
  IF v_tipo_produto_id = 0
  THEN
   -- nao achou nada. retorna o id do tipo_produto ND (nao definido)
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_id
     FROM tipo_produto
    WHERE empresa_id = p_empresa_id
      AND codigo = 'ND';
  END IF;
  --
  RETURN v_tipo_produto_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_tipo_produto_id := NULL;
   RETURN v_tipo_produto_id;
 END id_retornar;
 --
 --
 PROCEDURE duplicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias         ProcessMind     DATA: 17/06/2024
  -- DESCRICAO: Inclusão de TIPO_PRODUTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xx                99/99/9999  xx
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN empresa.empresa_id%TYPE,
  p_nome                     IN tipo_produto.nome%TYPE,
  p_cod_ext_produto          IN tipo_produto.cod_ext_produto%TYPE,
  p_tipo_produto_duplicar_id IN tipo_produto.tipo_produto_id%TYPE,
  p_vetor_preco_id           IN VARCHAR2,
  p_custo                    IN VARCHAR2,
  p_preco                    IN VARCHAR2,
  p_tipo_produto_id          OUT tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_tipo_produto_id tipo_produto.tipo_produto_id%TYPE;
  v_delimitador     CHAR(1);
  v_nome_var        VARCHAR2(100);
  v_nome_aux        VARCHAR2(100);
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt              := 0;
  p_tipo_produto_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_PRODUTO_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(p_nome, '|') > 0 OR instr(p_nome, ';') > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode conter pipe ou ponto-e-vírgula.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de produto já existe.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_produto.nextval
    INTO v_tipo_produto_id
    FROM dual;
  --
  INSERT INTO tipo_produto
   (tipo_produto_id,
    empresa_id,
    nome,
    codigo,
    flag_ativo,
    flag_sistema,
    variacoes,
    tempo_exec_info,
    tempo_exec_calc,
    cod_ext_produto,
    categoria_id,
    flag_tarefa,
    unidade_freq)
   SELECT v_tipo_produto_id,
          empresa_id,
          p_nome,
          p_cod_ext_produto,
          flag_ativo,
          flag_sistema,
          variacoes,
          tempo_exec_info,
          tempo_exec_calc,
          cod_ext_produto,
          categoria_id,
          flag_tarefa,
          unidade_freq
     FROM tipo_produto
    WHERE tipo_produto_id = p_tipo_produto_duplicar_id;
  --
  --copia a configuração de tipos de OS para o novo tipo de produto
  INSERT INTO tipo_prod_tipo_os
   (tipo_produto_id,
    tipo_os_id)
   SELECT v_tipo_produto_id,
          tipo_os_id
     FROM tipo_prod_tipo_os
    WHERE tipo_produto_id = p_tipo_produto_duplicar_id;
  --
  --copia os metadados para o novo tipo de produto
  INSERT INTO metadado
   (metadado_id,
    empresa_id,
    tipo_dado_id,
    metadado_cond_id,
    tipo_objeto,
    objeto_id,
    grupo,
    nome,
    tamanho,
    flag_obrigatorio,
    sufixo,
    instrucoes,
    valores,
    ordem,
    flag_ativo,
    flag_ao_lado,
    flag_na_lista,
    flag_ordenar,
    valor_cond,
    privilegio_id)
   SELECT seq_metadado.nextval,
          empresa_id,
          tipo_dado_id,
          metadado_cond_id,
          tipo_objeto,
          v_tipo_produto_id,
          grupo,
          nome,
          tamanho,
          flag_obrigatorio,
          sufixo,
          instrucoes,
          valores,
          ordem,
          flag_ativo,
          flag_ao_lado,
          flag_na_lista,
          flag_ordenar,
          valor_cond,
          privilegio_id
     FROM metadado
    WHERE objeto_id = p_tipo_produto_duplicar_id
      AND tipo_objeto = 'TIPO_PRODUTO';
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('TIPO_PRODUTO_ADICIONAR',
                           p_empresa_id,
                           v_tipo_produto_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ----------------------------------------------------------------------------------------
  -- Adicao subrotina sem commit, vincula tabela de preço à tipo_produto_preco
  ----------------------------------------------------------------------------------------
  preco_pkg.tipo_produto_vincular(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_tipo_produto_id,
                                  p_vetor_preco_id,
                                  p_custo,
                                  p_preco,
                                  p_erro_cod,
                                  p_erro_msg);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(v_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_produto_id,
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
  p_tipo_produto_id := v_tipo_produto_id;
  p_erro_cod        := '00000';
  p_erro_msg        := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- duplicar
--
--
END; -- TIPO_PRODUTO_PKG

/
