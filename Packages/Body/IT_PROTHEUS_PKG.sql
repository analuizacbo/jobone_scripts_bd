--------------------------------------------------------
--  DDL for Package Body IT_PROTHEUS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_PROTHEUS_PKG" IS
 --
 PROCEDURE log_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML principal enviado ao sistema externo ou o
  --   XML principal recebido pelo sistema externo (transacao autonoma, que faz commit mas
  --   nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id      IN NUMBER,
  p_sistema_origem  IN VARCHAR2,
  p_sistema_destino IN VARCHAR2,
  p_cod_objeto      IN VARCHAR2,
  p_cod_acao        IN VARCHAR2,
  p_objeto_id       IN VARCHAR2,
  p_xml_in          IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  IF p_xml_in IS NOT NULL
  THEN
   INSERT INTO xml_log
    (xml_log_id,
     data,
     texto_xml,
     retorno_xml,
     sistema_origem,
     sistema_destino,
     cod_objeto,
     cod_acao,
     objeto_id)
   VALUES
    (p_xml_log_id,
     SYSDATE,
     p_xml_in,
     'PENDENTE',
     p_sistema_origem,
     p_sistema_destino,
     p_cod_objeto,
     p_cod_acao,
     to_number(p_objeto_id));
  END IF;
  --
  COMMIT;
  --
 END log_gravar;
 --
 --
 PROCEDURE log_concluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML de retorno enviado pelo sistema externo ou
  --   o XML de retorno gerado pelo JobOne (transacao autonoma, que faz commit mas nao
  --   interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id IN NUMBER,
  p_objeto_id  IN VARCHAR2,
  p_xml_out    IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  IF p_xml_out IS NOT NULL
  THEN
   UPDATE xml_log
      SET retorno_xml = p_xml_out,
          objeto_id   = to_number(p_objeto_id)
    WHERE xml_log_id = p_xml_log_id;
  END IF;
  --
  COMMIT;
  --
 END log_concluir;
 --
 --
 --
 FUNCTION char_esp_protheus_retirar
 (
  -----------------------------------------------------------------------
  --   char_especial_retirar
  --
  --   Descricao: retira eventuais caracteres especiais de um dado string
  -----------------------------------------------------------------------
  p_string IN VARCHAR2
 ) RETURN VARCHAR2 IS
  --
  v_string VARCHAR2(32000);
  --
 BEGIN
  v_string := TRIM(p_string);
  --
  v_string := TRIM(REPLACE(v_string, chr(13), ''));
  v_string := TRIM(REPLACE(v_string, chr(10), ' '));
  --
  v_string := TRIM(REPLACE(v_string, '&', ' '));
  v_string := TRIM(REPLACE(v_string, '%', ' '));
  v_string := TRIM(REPLACE(v_string, '@', ' '));
  v_string := TRIM(REPLACE(v_string, '"', ' '));
  v_string := TRIM(REPLACE(v_string, '''', ' '));
  v_string := TRIM(REPLACE(v_string, 'º', ' '));
  v_string := TRIM(REPLACE(v_string, '°', ' '));
  v_string := TRIM(REPLACE(v_string, 'ª', ' '));
  --
  RETURN v_string;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_string := 'ERRO string';
   RETURN v_string;
 END char_esp_protheus_retirar;
 --
 --
 PROCEDURE pessoa_replicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/12/2020
  -- DESCRICAO: subrotina que replica dados da PESSOA para outras empresas.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_pessoa_id          pessoa.pessoa_id%TYPE;
  v_cnpj               pessoa.cnpj%TYPE;
  v_cpf                pessoa.cpf%TYPE;
  v_inscr_estadual     pessoa.inscr_estadual%TYPE;
  v_inscr_municipal    pessoa.inscr_municipal%TYPE;
  v_nome               pessoa.nome%TYPE;
  v_apelido            pessoa.apelido%TYPE;
  v_email              pessoa.email%TYPE;
  v_ddd_telefone       pessoa.ddd_telefone%TYPE;
  v_num_telefone       pessoa.num_telefone%TYPE;
  v_endereco           pessoa.endereco%TYPE;
  v_num_ender          pessoa.num_ender%TYPE;
  v_compl_ender        pessoa.compl_ender%TYPE;
  v_bairro             pessoa.bairro%TYPE;
  v_cidade             pessoa.cidade%TYPE;
  v_uf                 pessoa.uf%TYPE;
  v_cep                pessoa.cep%TYPE;
  v_pais               pessoa.pais%TYPE;
  v_flag_sem_docum     pessoa.flag_sem_docum%TYPE;
  v_flag_pessoa_jur    pessoa.flag_pessoa_jur%TYPE;
  v_tipo_pessoa_cli_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_for_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_est_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_ext_pessoa     pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_pessoa_cli pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_pessoa_for pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_cod_evento         VARCHAR2(40);
  v_xml_atual          CLOB;
  v_usuario_admin_id   usuario.usuario_id%TYPE;
  v_flag_estrangeiro   CHAR(1);
  --
  CURSOR c_em IS
   SELECT DISTINCT sp.empresa_id,
                   em.nome
     FROM sist_ext_ponto_int sp,
          ponto_integracao   pi,
          empresa            em
    WHERE sp.sistema_externo_id = p_sistema_externo_id
      AND sp.ponto_integracao_id = pi.ponto_integracao_id
      AND sp.empresa_id = em.empresa_id
      AND em.empresa_id <> p_empresa_id
      AND pi.codigo LIKE 'PESSOA_ATUALIZAR%';
  --
 BEGIN
  v_qt               := 0;
  v_flag_estrangeiro := 'N';
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa (' || to_char(p_pessoa_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_cli_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_for_id
    FROM tipo_pessoa
   WHERE codigo = 'FORNECEDOR';
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_est_id
    FROM tipo_pessoa
   WHERE codigo = 'ESTRANGEIRO';
  --
  SELECT MAX(cod_ext_pessoa)
    INTO v_cod_ext_pessoa_cli
    FROM pessoa_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = p_pessoa_id
     AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
  --
  SELECT MAX(cod_ext_pessoa)
    INTO v_cod_ext_pessoa_for
    FROM pessoa_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = p_pessoa_id
     AND tipo_pessoa_id = v_tipo_pessoa_for_id;
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'ESTRANGEIRO') = 1
  THEN
   v_flag_estrangeiro := 'S';
  END IF;
  --
  SELECT nome,
         apelido,
         cnpj,
         cpf,
         flag_pessoa_jur,
         flag_sem_docum,
         inscr_estadual,
         inscr_municipal,
         email,
         ddd_telefone,
         num_telefone,
         endereco,
         num_ender,
         compl_ender,
         bairro,
         cidade,
         uf,
         cep,
         pais
    INTO v_nome,
         v_apelido,
         v_cnpj,
         v_cpf,
         v_flag_pessoa_jur,
         v_flag_sem_docum,
         v_inscr_estadual,
         v_inscr_municipal,
         v_email,
         v_ddd_telefone,
         v_num_telefone,
         v_endereco,
         v_num_ender,
         v_compl_ender,
         v_bairro,
         v_cidade,
         v_uf,
         v_cep,
         v_pais
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_em IN c_em
  LOOP
   IF v_cnpj IS NOT NULL OR v_cpf IS NOT NULL
   THEN
    -- tenta localizar o registro na outra empresa
    -- pelo cnpj ou cpf
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE (cnpj = v_cnpj OR cpf = v_cpf)
       AND empresa_id = r_em.empresa_id;
   END IF;
   --
   IF v_pessoa_id IS NULL AND v_flag_estrangeiro = 'S'
   THEN
    -- pessoa no estrangeito. Tenta localizar o registro na
    -- outra empresa pelo nome
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE nome = v_nome
       AND cnpj IS NULL
       AND cpf IS NULL
       AND empresa_id = r_em.empresa_id;
   END IF;
   --
   IF v_pessoa_id IS NULL AND v_flag_estrangeiro = 'S'
   THEN
    -- pessoa no estrangeito. Tenta localizar o registro na
    -- outra empresa pelo apelido
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE apelido = v_apelido
       AND cnpj IS NULL
       AND cpf IS NULL
       AND empresa_id = r_em.empresa_id;
   END IF;
   --
   IF v_pessoa_id IS NULL
   THEN
    v_cod_evento := 'INCLUIR';
    --
    SELECT seq_pessoa.nextval
      INTO v_pessoa_id
      FROM dual;
    --
    INSERT INTO pessoa
     (empresa_id,
      pessoa_id,
      apelido,
      nome,
      cnpj,
      cpf,
      flag_sem_docum,
      flag_pessoa_jur,
      endereco,
      num_ender,
      compl_ender,
      bairro,
      cep,
      cidade,
      uf,
      pais,
      ddd_telefone,
      num_telefone,
      email,
      flag_emp_fatur,
      flag_emp_resp,
      flag_ativo,
      flag_pago_cliente)
    VALUES
     (r_em.empresa_id,
      v_pessoa_id,
      v_apelido,
      v_nome,
      v_cnpj,
      v_cpf,
      v_flag_sem_docum,
      v_flag_pessoa_jur,
      v_endereco,
      v_num_ender,
      v_compl_ender,
      v_bairro,
      v_cep,
      v_cidade,
      v_uf,
      v_pais,
      v_ddd_telefone,
      v_num_telefone,
      v_email,
      'N',
      'N',
      'S',
      'N');
    --
    -- cria os impostos usados por fornecedores
    INSERT INTO fi_tipo_imposto_pessoa
     (fi_tipo_imposto_pessoa_id,
      fi_tipo_imposto_id,
      pessoa_id,
      perc_imposto,
      flag_reter,
      nome_servico)
     SELECT seq_fi_tipo_imposto_pessoa.nextval,
            fi_tipo_imposto_id,
            v_pessoa_id,
            NULL,
            'N',
            NULL
       FROM fi_tipo_imposto
      WHERE flag_incide_ent = 'S';
   ELSE
    v_cod_evento := 'ALTERAR';
    --
    UPDATE pessoa
       SET nome            = v_nome,
           apelido         = v_apelido,
           inscr_estadual  = v_inscr_estadual,
           inscr_municipal = v_inscr_estadual,
           email           = v_email,
           ddd_telefone    = v_ddd_telefone,
           num_telefone    = v_num_telefone,
           endereco        = v_endereco,
           num_ender       = v_num_ender,
           compl_ender     = v_compl_ender,
           bairro          = v_bairro,
           cidade          = v_cidade,
           uf              = v_uf,
           cep             = v_cep,
           pais            = v_pais
     WHERE pessoa_id = v_pessoa_id;
   END IF;
   --
   ------------------------------------------------------------
   -- trata tipificacao e codigo externo da pessoa cliente
   ------------------------------------------------------------
   IF v_cod_ext_pessoa_cli IS NOT NULL
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa_cli_id);
    END IF;
    --
    SELECT MAX(cod_ext_pessoa)
      INTO v_cod_ext_pessoa
      FROM pessoa_sist_ext
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_cli_id
       AND sistema_externo_id = p_sistema_externo_id;
    --
    IF v_cod_ext_pessoa_cli <> v_cod_ext_pessoa
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse cliente já está integrado na empresa ' || r_em.nome ||
                   ' através do código (' || v_cod_ext_pessoa || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_cod_ext_pessoa IS NULL
    THEN
     INSERT INTO pessoa_sist_ext
      (sistema_externo_id,
       pessoa_id,
       tipo_pessoa_id,
       cod_ext_pessoa)
     VALUES
      (p_sistema_externo_id,
       v_pessoa_id,
       v_tipo_pessoa_cli_id,
       v_cod_ext_pessoa_cli);
    END IF;
   END IF; -- fim do IF v_cod_ext_pessoa_cli
   --
   ------------------------------------------------------------
   -- trata tipificacao e codigo externo da pessoa fornecedor
   ------------------------------------------------------------
   IF v_cod_ext_pessoa_for IS NOT NULL
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_for_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa_for_id);
    END IF;
    --
    SELECT MAX(cod_ext_pessoa)
      INTO v_cod_ext_pessoa
      FROM pessoa_sist_ext
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_for_id
       AND sistema_externo_id = p_sistema_externo_id;
    --
    IF v_cod_ext_pessoa_for <> v_cod_ext_pessoa
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse fornecedor já está integrado na empresa ' || r_em.nome ||
                   ' através do código (' || v_cod_ext_pessoa || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_cod_ext_pessoa IS NULL
    THEN
     INSERT INTO pessoa_sist_ext
      (sistema_externo_id,
       pessoa_id,
       tipo_pessoa_id,
       cod_ext_pessoa)
     VALUES
      (p_sistema_externo_id,
       v_pessoa_id,
       v_tipo_pessoa_for_id,
       v_cod_ext_pessoa_for);
    END IF;
   END IF; -- fim do IF v_cod_ext_pessoa_for
   --
   ------------------------------------------------------------
   -- trata tipificacao de pessoa no estrangeiro
   ------------------------------------------------------------
   IF v_flag_estrangeiro = 'S'
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_est_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa_est_id);
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := TRIM(v_nome);
   v_compl_histor   := 'Integração Protheus';
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_em.empresa_id,
                    'PESSOA',
                    v_cod_evento,
                    v_identif_objeto,
                    v_pessoa_id,
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
  END LOOP; -- fim do loop por empresa
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pessoa_replicar;
 --
 --
 --
 PROCEDURE pessoa_cli_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 09/12/2020
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de pessoas do
  --  tipo cliente.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/06/2021  O email vai sempre vazio para o Protheus.
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_xml_out            CLOB;
  v_xml_in             CLOB;
  v_flag_pessoa_jur    pessoa.flag_pessoa_jur%TYPE;
  v_cidade             pessoa.cidade%TYPE;
  v_uf                 pessoa.uf%TYPE;
  v_bairro             pessoa.bairro%TYPE;
  v_cep                pessoa.cep%TYPE;
  v_cod_obj_externo    pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_pais               pessoa.pais%TYPE;
  v_cpf_cnpj           pessoa.cnpj%TYPE;
  v_pessoa_nome        pessoa.nome%TYPE;
  v_pessoa_apelido     pessoa.apelido%TYPE;
  v_ddd_telefone       pessoa.ddd_telefone%TYPE;
  v_num_telefone       pessoa.num_telefone%TYPE;
  v_inscr_estadual     pessoa.inscr_estadual%TYPE;
  v_inscr_municipal    pessoa.inscr_municipal%TYPE;
  v_tipo_pessoa_cli_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_siscomex       pais.cod_siscomex%TYPE;
  v_cod_ext_pessoa     pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_qt_est             NUMBER(5);
  v_codigo_ibge        VARCHAR2(10);
  v_cod_pessoa         VARCHAR2(10);
  v_cod_loja           VARCHAR2(10);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.flag_pessoa_jur,
         pe.cidade,
         pe.nome,
         pe.apelido,
         nvl(pe.pais, 'BRASIL'),
         decode(flag_pessoa_jur, 'S', cnpj, 'N', cpf),
         pe.ddd_telefone,
         pe.num_telefone,
         nvl(pe.inscr_estadual, 'ISENTO'),
         pe.inscr_municipal,
         pe.uf,
         pe.bairro,
         pe.cep
    INTO v_flag_pessoa_jur,
         v_cidade,
         v_pessoa_nome,
         v_pessoa_apelido,
         v_pais,
         v_cpf_cnpj,
         v_ddd_telefone,
         v_num_telefone,
         v_inscr_estadual,
         v_inscr_municipal,
         v_uf,
         v_bairro,
         v_cep
    FROM pessoa pe
   WHERE pe.pessoa_id = p_pessoa_id;
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_cli_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     ti
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = p_pessoa_id
     AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
     AND ti.codigo = 'CLIENTE';
  --
  SELECT COUNT(*)
    INTO v_qt_est
    FROM tipific_pessoa tf,
         tipo_pessoa    tp
   WHERE tf.pessoa_id = p_pessoa_id
     AND tf.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'ESTRANGEIRO';
  --
  IF length(v_pessoa_nome) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social da pessoa não pode ter mais que 100 caracteres (' ||
                 v_pessoa_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_pessoa_apelido) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome fantasia da pessoa não pode ter mais que 100 caracteres (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_telefone := REPLACE(v_num_telefone, '-', '');
  --
  IF length(v_num_telefone) > 9 OR inteiro_validar(v_num_telefone) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do telefone inválido (' || v_num_telefone || ' - ' || v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_ddd_telefone) > 3 OR inteiro_validar(v_ddd_telefone) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do DDD do telefone inválido (' || v_ddd_telefone || ' - ' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  v_cidade := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade := char_especial_retirar(v_cidade);
  --
  v_bairro := util_pkg.acento_municipio_retirar(v_bairro);
  v_bairro := char_especial_retirar(v_bairro);
  --
  v_pessoa_nome    := char_especial_retirar(v_pessoa_nome);
  v_pessoa_apelido := char_especial_retirar(v_pessoa_apelido);
  --
  SELECT MAX(cod_siscomex)
    INTO v_cod_siscomex
    FROM pais
   WHERE upper(acento_retirar(v_pais)) = upper(acento_retirar(nome));
  --
  IF v_cod_siscomex IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código SISCOMEX do país não definido (' || v_pais || ' - ' || v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_est > 0 AND v_cod_siscomex = '105'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa indicada como no estrangeiro não pode ter endereço no Brasil (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_est = 0 AND v_cod_siscomex <> '105'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa com endereço fora do Brasil deve ser indicada como no estrangeiro (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_siscomex <> '105'
  THEN
   -- pessoa no estrangeito
   v_inscr_estadual := NULL;
   v_inscr_estadual := NULL;
   v_codigo_ibge    := NULL;
   v_uf             := 'EX';
  ELSE
   -- pessoa no brasil
   SELECT MAX(mu.codigo_ibge)
     INTO v_codigo_ibge
     FROM cep_uf     uf,
          cep_cidade mu
    WHERE uf.uf_sigla = upper(v_uf)
      AND uf.uf_id = mu.uf_id
      AND util_pkg.acento_municipio_retirar(mu.cidade_descricao) =
          util_pkg.acento_municipio_retirar(TRIM(v_cidade));
   --
   IF v_codigo_ibge IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código do município não encontrado (' || v_cidade || ').';
    RAISE v_exception;
   END IF;
   --
   -- retira os 2 primeiros digitos (estado)
   v_codigo_ibge := substr(v_codigo_ibge, 3);
  END IF;
  --
  IF v_cod_ext_pessoa IS NOT NULL
  THEN
   v_cod_pessoa := substr(v_cod_ext_pessoa, 1, instr(v_cod_ext_pessoa, '-') - 1);
   v_cod_loja   := substr(v_cod_ext_pessoa, instr(v_cod_ext_pessoa, '-') + 1);
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT REPLACE(json_object('cliente' VALUE
                             json_object('cliente_loja' VALUE
                                         nvl(REPLACE(v_cod_ext_pessoa, '-', ''), ' '),
                                         'razao_social' VALUE upper(acento_retirar(v_pessoa_nome)),
                                         'nome_fantasia' VALUE
                                         upper(acento_retirar(v_pessoa_apelido)),
                                         'cpf_cnpj' VALUE nvl(v_cpf_cnpj, ' '),
                                         'inscr_estadual' VALUE nvl(v_inscr_estadual, ' '),
                                         'inscr_municipal' VALUE nvl(v_inscr_municipal, ' '),
                                         'endereco' VALUE nvl(upper(acento_retirar(endereco)), ' '),
                                         'numero' VALUE nvl(num_ender, ' '),
                                         'complemento' VALUE
                                         nvl(upper(acento_retirar(compl_ender)), ' '),
                                         'estado' VALUE nvl(v_uf, ' '),
                                         'cod_municipio' VALUE nvl(v_codigo_ibge, ' '),
                                         'bairro' VALUE nvl(upper(acento_retirar(v_bairro)), ' '),
                                         'cep' VALUE nvl(v_cep, ' '),
                                         'pais' VALUE nvl(v_cod_siscomex, ' '),
                                         'email' VALUE nvl(NULL, ' '),
                                         'ddd' VALUE nvl(v_ddd_telefone, ' '),
                                         'telefone' VALUE nvl(v_num_telefone, ' '))),
                 '" "',
                 '""')
    INTO v_xml_in
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'PESSOA_CLI',
                    p_cod_acao,
                    p_pessoa_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_pessoa'))
     INTO v_cod_obj_externo
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_externo IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus da pessoa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa_sist_ext
    WHERE pessoa_id = p_pessoa_id
      AND sistema_externo_id = p_sistema_externo_id
      AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_cli_id,
      v_cod_obj_externo);
   ELSE
    UPDATE pessoa_sist_ext
       SET cod_ext_pessoa = v_cod_obj_externo
     WHERE pessoa_id = p_pessoa_id
       AND sistema_externo_id = p_sistema_externo_id
       AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
   END IF;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pessoa_cli_integrar;
 --
 --
 --
 PROCEDURE pessoa_for_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 09/12/2020
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de pessoas do
  --  tipo fornecedor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_xml_out            CLOB;
  v_xml_in             CLOB;
  v_flag_pessoa_jur    pessoa.flag_pessoa_jur%TYPE;
  v_cidade             pessoa.cidade%TYPE;
  v_uf                 pessoa.uf%TYPE;
  v_bairro             pessoa.bairro%TYPE;
  v_cep                pessoa.cep%TYPE;
  v_cod_obj_externo    pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_pais               pessoa.pais%TYPE;
  v_cpf_cnpj           pessoa.cnpj%TYPE;
  v_pessoa_nome        pessoa.nome%TYPE;
  v_pessoa_apelido     pessoa.apelido%TYPE;
  v_ddd_telefone       pessoa.ddd_telefone%TYPE;
  v_num_telefone       pessoa.num_telefone%TYPE;
  v_inscr_estadual     pessoa.inscr_estadual%TYPE;
  v_inscr_municipal    pessoa.inscr_municipal%TYPE;
  v_tipo_pessoa_for_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_siscomex       pais.cod_siscomex%TYPE;
  v_cod_ext_pessoa     pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_qt_est             NUMBER(5);
  v_codigo_ibge        VARCHAR2(10);
  v_cod_pessoa         VARCHAR2(10);
  v_cod_loja           VARCHAR2(10);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.flag_pessoa_jur,
         pe.cidade,
         pe.nome,
         pe.apelido,
         nvl(pe.pais, 'BRASIL'),
         decode(flag_pessoa_jur, 'S', cnpj, 'N', cpf),
         pe.ddd_telefone,
         pe.num_telefone,
         nvl(pe.inscr_estadual, 'ISENTO'),
         pe.inscr_municipal,
         pe.uf,
         pe.bairro,
         pe.cep
    INTO v_flag_pessoa_jur,
         v_cidade,
         v_pessoa_nome,
         v_pessoa_apelido,
         v_pais,
         v_cpf_cnpj,
         v_ddd_telefone,
         v_num_telefone,
         v_inscr_estadual,
         v_inscr_municipal,
         v_uf,
         v_bairro,
         v_cep
    FROM pessoa pe
   WHERE pe.pessoa_id = p_pessoa_id;
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_for_id
    FROM tipo_pessoa
   WHERE codigo = 'FORNECEDOR';
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     ti
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = p_pessoa_id
     AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
     AND ti.codigo = 'FORNECEDOR';
  --
  SELECT COUNT(*)
    INTO v_qt_est
    FROM tipific_pessoa tf,
         tipo_pessoa    tp
   WHERE tf.pessoa_id = p_pessoa_id
     AND tf.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'ESTRANGEIRO';
  --
  IF length(v_pessoa_nome) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social da pessoa não pode ter mais que 100 caracteres (' ||
                 v_pessoa_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_pessoa_apelido) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome fantasia da pessoa não pode ter mais que 100 caracteres (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_telefone := REPLACE(v_num_telefone, '-', '');
  --
  IF length(v_num_telefone) > 9 OR inteiro_validar(v_num_telefone) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do telefone inválido (' || v_num_telefone || ' - ' || v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_ddd_telefone) > 3 OR inteiro_validar(v_ddd_telefone) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do DDD do telefone inválido (' || v_ddd_telefone || ' - ' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  v_cidade := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade := char_especial_retirar(v_cidade);
  --
  v_bairro := util_pkg.acento_municipio_retirar(v_bairro);
  v_bairro := char_especial_retirar(v_bairro);
  --
  v_pessoa_nome    := char_especial_retirar(v_pessoa_nome);
  v_pessoa_apelido := char_especial_retirar(v_pessoa_apelido);
  --
  SELECT MAX(cod_siscomex)
    INTO v_cod_siscomex
    FROM pais
   WHERE upper(acento_retirar(v_pais)) = upper(acento_retirar(nome));
  --
  IF v_cod_siscomex IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código SISCOMEX do país não definido (' || v_pais || ' - ' || v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_est > 0 AND v_cod_siscomex = '105'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa indicada como no estrangeiro não pode ter endereço no Brasil (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_est = 0 AND v_cod_siscomex <> '105'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa com endereço fora do Brasil deve ser indicada como no estrangeiro (' ||
                 v_pessoa_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_siscomex <> '105'
  THEN
   -- pessoa no estrangeito
   v_inscr_estadual := NULL;
   v_inscr_estadual := NULL;
   v_codigo_ibge    := NULL;
   v_uf             := 'EX';
  ELSE
   -- pessoa no brasil
   SELECT MAX(mu.codigo_ibge)
     INTO v_codigo_ibge
     FROM cep_uf     uf,
          cep_cidade mu
    WHERE uf.uf_sigla = upper(v_uf)
      AND uf.uf_id = mu.uf_id
      AND util_pkg.acento_municipio_retirar(mu.cidade_descricao) =
          util_pkg.acento_municipio_retirar(TRIM(v_cidade));
   --
   IF v_codigo_ibge IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código do município não encontrado (' || v_cidade || ').';
    RAISE v_exception;
   END IF;
   --
   -- retira os 2 primeiros digitos (estado)
   v_codigo_ibge := substr(v_codigo_ibge, 3);
  END IF;
  --
  IF v_cod_ext_pessoa IS NOT NULL
  THEN
   v_cod_pessoa := substr(v_cod_ext_pessoa, 1, instr(v_cod_ext_pessoa, '-') - 1);
   v_cod_loja   := substr(v_cod_ext_pessoa, instr(v_cod_ext_pessoa, '-') + 1);
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT REPLACE(json_object('fornecedor' VALUE
                             json_object('fornecedor_loja' VALUE
                                         nvl(REPLACE(v_cod_ext_pessoa, '-', ''), ' '),
                                         'razao_social' VALUE upper(acento_retirar(v_pessoa_nome)),
                                         'nome_fantasia' VALUE
                                         upper(acento_retirar(v_pessoa_apelido)),
                                         'cpf_cnpj' VALUE nvl(v_cpf_cnpj, ' '),
                                         'inscr_estadual' VALUE nvl(v_inscr_estadual, ' '),
                                         'inscr_municipal' VALUE nvl(v_inscr_municipal, ' '),
                                         'endereco' VALUE nvl(upper(acento_retirar(endereco)), ' '),
                                         'numero' VALUE nvl(num_ender, ' '),
                                         'complemento' VALUE
                                         nvl(upper(acento_retirar(compl_ender)), ' '),
                                         'estado' VALUE nvl(v_uf, ' '),
                                         'cod_municipio' VALUE nvl(v_codigo_ibge, ' '),
                                         'bairro' VALUE nvl(upper(acento_retirar(v_bairro)), ' '),
                                         'cep' VALUE nvl(v_cep, ' '),
                                         'pais' VALUE nvl(v_cod_siscomex, ' '),
                                         'email' VALUE nvl(email, ' '),
                                         'ddd' VALUE nvl(v_ddd_telefone, ' '),
                                         'telefone' VALUE nvl(v_num_telefone, ' '))),
                 '" "',
                 '""')
    INTO v_xml_in
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'PESSOA_FOR',
                    p_cod_acao,
                    p_pessoa_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_pessoa'))
     INTO v_cod_obj_externo
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_externo IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus da pessoa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa_sist_ext
    WHERE pessoa_id = p_pessoa_id
      AND sistema_externo_id = p_sistema_externo_id
      AND tipo_pessoa_id = v_tipo_pessoa_for_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_for_id,
      v_cod_obj_externo);
   ELSE
    UPDATE pessoa_sist_ext
       SET cod_ext_pessoa = v_cod_obj_externo
     WHERE pessoa_id = p_pessoa_id
       AND sistema_externo_id = p_sistema_externo_id
       AND tipo_pessoa_id = v_tipo_pessoa_for_id;
   END IF;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pessoa_for_integrar;
 --
 --
 --
 PROCEDURE pv_orcam_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/03/2021
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de pedido de venda
  --   proveniente de orcamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_orcamento_id       IN orcamento.orcamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_xml_out        CLOB;
  v_xml_in         CLOB;
  v_emp_resp_id    job.emp_resp_id%TYPE;
  v_emp_fatur_id   orcamento.emp_faturar_por_id%TYPE;
  v_cod_ext_pedido orcamento.cod_ext_orcam%TYPE;
  v_data_prev_ini  orcamento.data_prev_ini%TYPE;
  v_data_prev_fim  orcamento.data_prev_fim%TYPE;
  v_servico_id     orcamento.servico_id%TYPE;
  v_obs_fatur      orcamento.obs_fatur%TYPE;
  v_flag_despesa   orcamento.flag_despesa%TYPE;
  v_valor_aprovado item.valor_aprovado%TYPE;
  v_cod_ext_resp   empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_empresa_filial empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_id_jobone      NUMBER(20);
  v_id_jobone_item NUMBER(20);
  v_programa       VARCHAR2(100);
  v_status         VARCHAR2(20);
  v_produto        VARCHAR2(20);
  v_nucleo         VARCHAR2(20);
  v_classe_valor   VARCHAR2(20);
  v_pedido_cliente VARCHAR2(20);
  v_data_inicio    VARCHAR2(20);
  v_data_termino   VARCHAR2(20);
  v_lbl_job        VARCHAR2(100);
  v_data_ini       DATE;
  v_data_fim       DATE;
  v_obs            VARCHAR2(200);
  v_permite_codrep VARCHAR2(20);
  --
 BEGIN
  v_qt             := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_permite_codrep := empresa_pkg.parametro_retornar(p_empresa_id, 'PERMITIR_CODREP_CTRORC');
  v_programa       := 'ORC';
  v_status         := 'P';
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.emp_resp_id,
         oc.emp_faturar_por_id,
         un.cod_ext_unid_neg,
         oc.cod_externo,
         oc.ordem_compra,
         oc.data_prev_ini,
         oc.data_prev_fim,
         oc.servico_id,
         to_char(jo.numero) || ' - ' || TRIM(jo.nome),
         oc.obs_fatur,
         oc.flag_despesa
    INTO v_emp_resp_id,
         v_emp_fatur_id,
         v_nucleo,
         v_classe_valor,
         v_pedido_cliente,
         v_data_prev_ini,
         v_data_prev_fim,
         v_servico_id,
         v_obs,
         v_obs_fatur,
         v_flag_despesa
    FROM orcamento       oc,
         job             jo,
         unidade_negocio un
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id
     AND jo.unidade_negocio_id = un.unidade_negocio_id(+);
  --
  -- a camada IT_CONTROLE ja pula o processamento em caso de DESPESA.
  -- teste por seguranca.
  IF v_flag_despesa = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Estimativa de custos do tipo Despesa não pode gerar pedido de venda.';
   RAISE v_exception;
  END IF;
  --
  v_id_jobone      := to_number('11' || TRIM(to_char(p_orcamento_id, '0000000009')));
  v_id_jobone_item := p_orcamento_id;
  v_obs            := substr(v_obs, 1, 100);
  v_data_inicio    := to_char(v_data_prev_ini, 'YYYYMMDD');
  v_data_termino   := to_char(v_data_prev_fim, 'YYYYMMDD');
  -- nao usa a ordem de comprra no pedido_cliente. Passa fixo.
  v_pedido_cliente := 'S';
  v_obs_fatur      := char_esp_protheus_retirar(v_obs_fatur);
  v_obs_fatur      := substr(v_obs_fatur, 1, 250);
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_resp IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa responsável pelo ' || v_lbl_job ||
                 ' (unidade de negócio) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_empresa_filial
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_fatur_id;
  --
  IF v_empresa_filial IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa de faturamento da estimativa de custos ' ||
                 '(empresa/filial) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_servico)
    INTO v_produto
    FROM pessoa_servico
   WHERE pessoa_id = v_emp_resp_id
     AND servico_id = v_servico_id;
  --
  IF v_produto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do produto associado à empresa responsável pelo ' || v_lbl_job ||
                 ' (produto) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_aprovado
    FROM item
   WHERE orcamento_id = p_orcamento_id
     AND flag_pago_cliente = 'N';
  --
  IF TRIM(v_classe_valor) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da estimatva de custos ' ||
                 '(classe de valor) não foi definido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_nucleo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do núcleo do ' || v_lbl_job || ' não foi definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_permite_codrep = 'N'
  THEN
   -- classe de valor (cod_externo) nao pode repetir
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento oc,
          job       jo
    WHERE jo.empresa_id = p_empresa_id
      AND jo.job_id = oc.job_id
      AND oc.orcamento_id <> p_orcamento_id
      AND oc.cod_externo = v_classe_valor;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código externo (classe de valor) já existe em ' ||
                  'outra estimativa de custos (' || v_classe_valor || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato         ct,
          contrato_servico cs
    WHERE ct.empresa_id = p_empresa_id
      AND ct.contrato_id = cs.contrato_id
      AND cs.cod_externo = v_classe_valor;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código externo (classe de valor) já existe em ' || 'produto de contrato (' ||
                  v_classe_valor || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  IF p_cod_acao IN ('I', 'A')
  THEN
   SELECT REPLACE(json_object('pedidodevenda' VALUE
                              json_object('cabecalho' VALUE
                                          json_object('id_jobone' VALUE v_id_jobone,
                                                      'status' VALUE v_status,
                                                      'programa' VALUE v_programa,
                                                      'empresa_filial' VALUE v_empresa_filial,
                                                      'unidade_negocio' VALUE v_cod_ext_resp),
                                          'itens' VALUE
                                          json_arrayagg(json_object('produto' VALUE
                                                                    nvl(v_produto, ' '),
                                                                    'quantidade' VALUE 1,
                                                                    'preco_unitario' VALUE
                                                                    v_valor_aprovado,
                                                                    'nucleo' VALUE nvl(v_nucleo, ' '),
                                                                    'classe_valor' VALUE
                                                                    nvl(v_classe_valor, ' '),
                                                                    'inicio_contrato' VALUE
                                                                    nvl(v_data_inicio, ' '),
                                                                    'final_contrato' VALUE
                                                                    nvl(v_data_termino, ' '),
                                                                    'mes_referencia' VALUE
                                                                    to_char(SYSDATE, 'YYYYMMDD'),
                                                                    'observacao' VALUE nvl(upper(acento_retirar(v_obs)),
                                                                        ' '),
                                                                    'pedido_cliente' VALUE
                                                                    nvl(v_pedido_cliente, 'S'),
                                                                    'id_jobone_item' VALUE
                                                                    to_char(v_id_jobone_item))))),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  IF p_cod_acao IN ('E')
  THEN
   SELECT REPLACE(json_object('pedidodevenda' VALUE
                              json_object('id_jobone' VALUE v_id_jobone,
                                          'empresa_filial' VALUE v_empresa_filial)),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'ORCAMENTO',
                    p_cod_acao,
                    p_orcamento_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_pedido'))
     INTO v_cod_ext_pedido
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_pedido IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus do pedido de venda.';
    RAISE v_exception;
   END IF;
   --
   UPDATE orcamento
      SET cod_ext_orcam = v_cod_ext_pedido
    WHERE orcamento_id = p_orcamento_id;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pv_orcam_integrar;
 --
 --
 --
 PROCEDURE pv_contrato_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/03/2021
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de pedido de venda
  --   proveniente de servico do contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/07/2022  Pula envio de PV totalmente faturado.
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_cod_acao            IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_saida              EXCEPTION;
  v_xml_out            CLOB;
  v_xml_in             CLOB;
  v_contrato_id        contrato.contrato_id%TYPE;
  v_emp_resp_id        contrato.emp_resp_id%TYPE;
  v_emp_fatur_id       contrato_servico.emp_faturar_por_id%TYPE;
  v_cod_ext_pedido     contrato_servico.cod_ext_ctrser%TYPE;
  v_servico_id         contrato_servico.servico_id%TYPE;
  v_usuario_resp_id    contrato_usuario.usuario_id%TYPE;
  v_valor_servico      contrato_serv_valor.valor_servico%TYPE;
  v_valor_faturado     parcela_fatur_ctr.valor_fatura%TYPE;
  v_cod_ext_resp       empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_empresa_filial     empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_unidade_negocio_id unidade_negocio.unidade_negocio_id%TYPE;
  v_id_jobone          NUMBER(20);
  v_programa           VARCHAR2(100);
  v_status             VARCHAR2(20);
  v_produto            VARCHAR2(20);
  v_nucleo             VARCHAR2(20);
  v_classe_valor       VARCHAR2(20);
  v_pedido_cliente     VARCHAR2(20);
  v_lbl_un             VARCHAR2(100);
  v_data_ini           DATE;
  v_data_fim           DATE;
  v_obs                VARCHAR2(200);
  v_permite_codrep     VARCHAR2(20);
  --
 BEGIN
  v_qt             := 0;
  v_lbl_un         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  v_permite_codrep := empresa_pkg.parametro_retornar(p_empresa_id, 'PERMITIR_CODREP_CTRORC');
  v_status         := 'P';
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.emp_resp_id,
         cs.emp_faturar_por_id,
         cs.cod_externo,
         ct.ordem_compra,
         cs.servico_id,
         ct.contrato_id,
         tc.cod_ext_tipo,
         contrato_pkg.numero_formatar(ct.contrato_id) || ' - ' || TRIM(ct.nome),
         cs.data_inicio,
         cs.data_termino
    INTO v_emp_resp_id,
         v_emp_fatur_id,
         v_classe_valor,
         v_pedido_cliente,
         v_servico_id,
         v_contrato_id,
         v_programa,
         v_obs,
         v_data_ini,
         v_data_fim
    FROM contrato         ct,
         contrato_servico cs,
         tipo_contrato    tc
   WHERE cs.contrato_servico_id = p_contrato_servico_id
     AND cs.contrato_id = ct.contrato_id
     AND ct.tipo_contrato_id = tc.tipo_contrato_id;
  --
  v_id_jobone := to_number('22' || TRIM(to_char(p_contrato_servico_id, '0000000009')));
  v_obs       := substr(v_obs, 1, 100);
  -- nao usa a ordem de comprra no pedido_cliente. Passa fixo.
  v_pedido_cliente := 'S';
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_resp_id
    FROM contrato_usuario
   WHERE contrato_id = v_contrato_id
     AND flag_responsavel = 'S';
  --
  IF v_usuario_resp_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O contrato não tem usuário responsável definido.';
   RAISE v_exception;
  END IF;
  --
  v_unidade_negocio_id := usuario_pkg.unid_negocio_retornar(v_usuario_resp_id,
                                                            p_empresa_id,
                                                            NULL,
                                                            NULL);
  --
  IF v_unidade_negocio_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário responsável pelo contrato não tem ' || v_lbl_un || ' definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_unid_neg)
    INTO v_nucleo
    FROM unidade_negocio
   WHERE unidade_negocio_id = v_unidade_negocio_id;
  --
  IF v_emp_resp_id IS NULL
  THEN
   -- empresa responsavel nao definida no contrato.
   -- pega do servico.
   SELECT MAX(emp_resp_id)
     INTO v_emp_resp_id
     FROM contrato_serv_valor
    WHERE contrato_servico_id = p_contrato_servico_id;
  END IF;
  --
  IF v_emp_resp_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Contrato ou produto sem empresa responsável definida.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_resp IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa responsável pelo contrato ' ||
                 '(unidade de negócio) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_empresa_filial
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_fatur_id;
  --
  IF v_empresa_filial IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa de faturamento do contrato ' ||
                 '(empresa/filial) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_servico)
    INTO v_produto
    FROM pessoa_servico
   WHERE pessoa_id = v_emp_resp_id
     AND servico_id = v_servico_id;
  --
  IF v_produto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do produto associado à empresa responsável pelo contrato ' ||
                 '(produto) não está definido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_programa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do tipo de contrato não foi definido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_classe_valor) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do produto do contrato ' ||
                 '(classe de valor) não foi definido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_nucleo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do núcleo do usuário ' ||
                 'responsável pelo contrato não foi definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_permite_codrep = 'N'
  THEN
   -- classe de valor (cod_externo) nao pode repetir entre contratos diferentes
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento oc,
          job       jo
    WHERE jo.empresa_id = p_empresa_id
      AND jo.job_id = oc.job_id
      AND oc.cod_externo = v_classe_valor;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código externo (classe de valor) já existe em ' || 'estimativa de custos (' ||
                  v_classe_valor || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato         ct,
          contrato_servico cs
    WHERE ct.empresa_id = p_empresa_id
      AND ct.contrato_id = cs.contrato_id
      AND cs.cod_externo = v_classe_valor
      AND cs.contrato_servico_id <> p_contrato_servico_id
      AND ct.contrato_id <> v_contrato_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código externo (classe de valor) já existe em ' ||
                  'produto de outro contrato (' || v_classe_valor || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT nvl(SUM(valor_parcela), 0)
    INTO v_valor_servico
    FROM parcela_contrato
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  SELECT nvl(SUM(pf.valor_fatura), 0)
    INTO v_valor_faturado
    FROM parcela_fatur_ctr pf,
         parcela_contrato  pc
   WHERE pc.contrato_servico_id = p_contrato_servico_id
     AND pc.parcela_contrato_id = pf.parcela_contrato_id;
  --
  IF p_cod_acao = 'A' AND v_valor_servico = v_valor_faturado
  THEN
   -- servico/PV ja totalmente faturado.
   -- pula o envio para o Protheus.
   RAISE v_saida;
  END IF;
  --
  /*
    SELECT MIN(data_vencim),
           MAX(data_vencim)
      INTO v_data_ini,
           v_data_fim
      FROM parcela_contrato
     WHERE contrato_id = v_contrato_id
       AND contrato_servico_id = p_contrato_servico_id;
  */
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  IF p_cod_acao IN ('I', 'A')
  THEN
   SELECT REPLACE(json_object('pedidodevenda' VALUE
                              json_object('cabecalho' VALUE
                                          json_object('id_jobone' VALUE v_id_jobone,
                                                      'status' VALUE v_status,
                                                      'programa' VALUE nvl(v_programa, ' '),
                                                      'empresa_filial' VALUE v_empresa_filial,
                                                      'unidade_negocio' VALUE v_cod_ext_resp
                                                      RETURNING CLOB),
                                          'itens' VALUE
                                          json_arrayagg(json_object('produto' VALUE
                                                                    nvl(v_produto, ' '),
                                                                    'quantidade' VALUE 1,
                                                                    'preco_unitario' VALUE
                                                                    valor_parcela,
                                                                    'nucleo' VALUE nvl(v_nucleo, ' '),
                                                                    'classe_valor' VALUE
                                                                    nvl(v_classe_valor, ' '),
                                                                    'inicio_contrato' VALUE
                                                                    to_char(v_data_ini, 'YYYYMMDD'),
                                                                    'final_contrato' VALUE
                                                                    to_char(v_data_fim, 'YYYYMMDD'),
                                                                    'mes_referencia' VALUE
                                                                    to_char(data_vencim, 'YYYYMMDD'),
                                                                    'observacao' VALUE nvl(upper(acento_retirar(v_obs)),
                                                                        ' '),
                                                                    'pedido_cliente' VALUE
                                                                    nvl(v_pedido_cliente, 'S'),
                                                                    'id_jobone_item' VALUE
                                                                    to_char(parcela_contrato_id)
                                                                    RETURNING CLOB) RETURNING CLOB)
                                          RETURNING CLOB) RETURNING CLOB),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM parcela_contrato
    WHERE contrato_id = v_contrato_id
      AND contrato_servico_id = p_contrato_servico_id
    ORDER BY num_parcela;
  END IF;
  --
  IF p_cod_acao IN ('E')
  THEN
   SELECT REPLACE(json_object('pedidodevenda' VALUE
                              json_object('id_jobone' VALUE v_id_jobone,
                                          'empresa_filial' VALUE v_empresa_filial)),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'CONTRATO',
                    p_cod_acao,
                    p_contrato_servico_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_pedido'))
     INTO v_cod_ext_pedido
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_pedido IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus do pedido de venda.';
    RAISE v_exception;
   END IF;
   --
   UPDATE contrato_servico
      SET cod_ext_ctrser = v_cod_ext_pedido
    WHERE contrato_servico_id = p_contrato_servico_id;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pv_contrato_integrar;
 --
 --
 --
 PROCEDURE nf_entrada_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2021
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de nota fiscal de
  --  entrada (pre-nota)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_xml_out             CLOB;
  v_xml_in              CLOB;
  v_job_id              item.job_id%TYPE;
  v_orcamento_id        item.orcamento_id%TYPE;
  v_emp_resp_id         job.emp_resp_id%TYPE;
  v_contrato_id         job.contrato_id%TYPE;
  v_cod_ext_nf          nota_fiscal.cod_ext_nf%TYPE;
  v_emp_fatur_id        nota_fiscal.emp_faturar_por_id%TYPE;
  v_num_doc             nota_fiscal.num_doc%TYPE;
  v_serie               nota_fiscal.serie%TYPE;
  v_chave_acesso        nota_fiscal.chave_acesso%TYPE;
  v_flag_despesa        orcamento.flag_despesa%TYPE;
  v_servico_id          orcamento.servico_id%TYPE;
  v_valor_nota          item_nota.valor_aprovado%TYPE;
  v_cod_ext_doc         tipo_doc_nf.cod_ext_doc%TYPE;
  v_cod_ext_condicao    condicao_pagto.cod_ext_condicao%TYPE;
  v_cod_ext_produto     produto_fiscal.cod_ext_produto%TYPE;
  v_contrato_servico_id contrato_servico.contrato_servico_id%TYPE;
  v_cnpj_cpf            VARCHAR2(50);
  v_id_jobone           NUMBER(20);
  v_id_jobone_pv        NUMBER(20);
  v_cod_ext_resp        empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_empresa_filial      empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_usuario_resp_id     contrato_usuario.usuario_id%TYPE;
  v_unidade_negocio_id  unidade_negocio.unidade_negocio_id%TYPE;
  v_produto             VARCHAR2(20);
  v_nucleo              VARCHAR2(20);
  v_natureza            VARCHAR2(20);
  v_classe_valor        VARCHAR2(20);
  v_lbl_job             VARCHAR2(100);
  v_lbl_un              VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_un  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT decode(pe.flag_pessoa_jur, 'S', pe.cnpj, pe.cpf),
         nf.produto,
         nf.emp_faturar_por_id,
         nf.num_doc,
         nf.serie,
         nf.chave_acesso,
         td.cod_ext_doc,
         cp.cod_ext_condicao,
         pf.cod_ext_produto
    INTO v_cnpj_cpf,
         v_produto,
         v_emp_fatur_id,
         v_num_doc,
         v_serie,
         v_chave_acesso,
         v_cod_ext_doc,
         v_cod_ext_condicao,
         v_natureza
    FROM nota_fiscal    nf,
         pessoa         pe,
         tipo_doc_nf    td,
         condicao_pagto cp,
         produto_fiscal pf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
     AND nf.condicao_pagto_id = cp.condicao_pagto_id(+)
     AND nf.produto_fiscal_id = pf.produto_fiscal_id(+);
  --
  SELECT MAX(orcamento_id),
         nvl(SUM(io.valor_aprovado), 0)
    INTO v_orcamento_id,
         v_valor_nota
    FROM item_nota io,
         item      it
   WHERE io.nota_fiscal_id = p_nota_fiscal_id
     AND io.item_id = it.item_id;
  --
  SELECT jo.emp_resp_id,
         un.cod_ext_unid_neg,
         oc.cod_externo,
         oc.flag_despesa,
         oc.servico_id,
         jo.contrato_id
    INTO v_emp_resp_id,
         v_nucleo,
         v_classe_valor,
         v_flag_despesa,
         v_servico_id,
         v_contrato_id
    FROM orcamento       oc,
         job             jo,
         unidade_negocio un
   WHERE oc.orcamento_id = v_orcamento_id
     AND oc.job_id = jo.job_id
     AND jo.unidade_negocio_id = un.unidade_negocio_id(+);
  --
  ------------------------------------------------------------
  -- tratamento de orcamento de despesa (pega dados do contrato)
  ------------------------------------------------------------
  IF v_flag_despesa = 'S'
  THEN
   IF v_contrato_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não está associado a um contrato.';
    RAISE v_exception;
   END IF;
   --
   IF v_servico_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa estimativa de custos não está associada a um produto.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(contrato_servico_id)
     INTO v_contrato_servico_id
     FROM contrato_servico
    WHERE contrato_id = v_contrato_id
      AND servico_id = v_servico_id
      AND cod_externo IS NOT NULL;
   --
   -- a classe de valor vem do contrato
   SELECT MAX(cod_externo)
     INTO v_classe_valor
     FROM contrato_servico
    WHERE contrato_servico_id = v_contrato_servico_id;
   --
   SELECT MAX(usuario_id)
     INTO v_usuario_resp_id
     FROM contrato_usuario
    WHERE contrato_id = v_contrato_id
      AND flag_responsavel = 'S';
   --
   IF v_usuario_resp_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O contrato não tem usuário responsável definido.';
    RAISE v_exception;
   END IF;
   --
   v_unidade_negocio_id := usuario_pkg.unid_negocio_retornar(v_usuario_resp_id,
                                                             p_empresa_id,
                                                             NULL,
                                                             NULL);
   --
   IF v_unidade_negocio_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário responsável pelo contrato não tem ' || v_lbl_un || ' definido.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(cod_ext_unid_neg)
     INTO v_nucleo
     FROM unidade_negocio
    WHERE unidade_negocio_id = v_unidade_negocio_id;
  END IF; -- fim do IF v_flag_despesa = 'S'
  --
  IF length(v_num_doc) > 9
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para a integração com o Protheus, o número da nota fiscal não pode ter mais do que 9 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo para esse tipo de documento ' || 'não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_resp IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa responsável pelo ' || v_lbl_job ||
                 ' (unidade de negócio) não está definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_empresa_filial
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_fatur_id;
  --
  IF v_empresa_filial IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa de faturamento do documento ' ||
                 '(empresa/filial) não está definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_produto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O produto do documento não está definido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_classe_valor) IS NULL
  THEN
   IF v_flag_despesa = 'N'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código externo da estimativa de custos ' ||
                  '(classe de valor) não foi definido.';
    RAISE v_exception;
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'O código externo do produto do contrato ' ||
                  '(classe de valor) não foi definido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(v_nucleo) IS NULL
  THEN
   IF v_flag_despesa = 'N'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código externo do núcleo do ' || v_lbl_job || ' não foi definido.';
    RAISE v_exception;
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'O código externo do núcleo do usuário ' ||
                  'responsável pelo contrato não foi definido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(v_cod_ext_condicao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da condição de pagamento não foi definido.';
   RAISE v_exception;
  END IF;
  --
  v_id_jobone := p_nota_fiscal_id;
  --
  IF v_flag_despesa = 'N'
  THEN
   v_id_jobone_pv := to_number('11' || TRIM(to_char(v_orcamento_id, '0000000009')));
  ELSE
   v_id_jobone_pv := to_number('22' || TRIM(to_char(v_contrato_servico_id, '0000000009')));
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  IF p_cod_acao IN ('I', 'A')
  THEN
   SELECT REPLACE(json_object('prenotaentrada' VALUE
                              json_object('cabecalho' VALUE
                                          json_object('id_jobone' VALUE v_id_jobone,
                                                      'id_jobone_pv' VALUE v_id_jobone_pv,
                                                      'empresa_filial' VALUE
                                                      nvl(v_empresa_filial, ' '),
                                                      'cpf_cnpj' VALUE nvl(v_cnpj_cpf, ' '),
                                                      'tipo_documento' VALUE nvl(v_cod_ext_doc, ' '),
                                                      'nota_fiscal' VALUE nvl(v_num_doc, ' '),
                                                      'serie_nota' VALUE nvl(v_serie, ' '),
                                                      'chave_nfe' VALUE nvl(v_chave_acesso, ' '),
                                                      'condicao_pagamento' VALUE
                                                      nvl(v_cod_ext_condicao, ' ')),
                                          'itens' VALUE
                                          json_arrayagg(json_object('produto' VALUE
                                                                    nvl(v_produto, ' '),
                                                                    'quantidade' VALUE 1,
                                                                    'preco_unitario' VALUE
                                                                    v_valor_nota,
                                                                    'natureza' VALUE
                                                                    nvl(v_natureza, ' '),
                                                                    'unidade_negocio' VALUE
                                                                    nvl(v_cod_ext_resp, ' '),
                                                                    'nucleo' VALUE nvl(v_nucleo, ' '),
                                                                    'classe_valor' VALUE
                                                                    nvl(v_classe_valor, ' '))))),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  IF p_cod_acao IN ('E')
  THEN
   SELECT REPLACE(json_object('prenotaentrada' VALUE
                              json_object('id_jobone' VALUE v_id_jobone,
                                          'empresa_filial' VALUE v_empresa_filial)),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'NOTA_FISCAL_ENTRADA',
                    p_cod_acao,
                    p_nota_fiscal_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_nf'))
     INTO v_cod_ext_nf
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_nf IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus da nota fiscal de entrada.';
    RAISE v_exception;
   END IF;
   --
   UPDATE nota_fiscal
      SET cod_ext_nf = v_cod_ext_nf
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END nf_entrada_integrar;
 --
 --
 --
 PROCEDURE faturamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/04/2021
  -- DESCRICAO: Subrotina que gera o json e processa a integracao de faturamento
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_tipo_fat           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_xml_out                 CLOB;
  v_xml_in                  CLOB;
  v_emp_fatur_id            faturamento.emp_faturar_por_id%TYPE;
  v_cod_ext_fatur           faturamento.cod_ext_fatur%TYPE;
  v_num_parcela             faturamento.num_parcela%TYPE;
  v_descricao               faturamento.descricao%TYPE;
  v_empresa_filial          empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_nota_fiscal             VARCHAR2(20);
  v_serie_nota_fiscal       VARCHAR2(20);
  v_id_jobone               NUMBER(20);
  v_id_jobone_fatura        VARCHAR2(20);
  v_id_jobone_item          VARCHAR2(4000);
  v_orcamento_id            orcamento.orcamento_id%TYPE;
  v_valor_fatura            item_fatur.valor_fatura%TYPE;
  v_valor_orcam             item_fatur.valor_fatura%TYPE;
  v_contrato_servico_id     contrato_servico.contrato_servico_id%TYPE;
  v_contrato_servico_id_aux contrato_servico.contrato_servico_id%TYPE;
  --
  CURSOR c_pa IS
   SELECT DISTINCT parcela_contrato_id
     FROM parcela_fatur_ctr
    WHERE faturamento_ctr_id = p_faturamento_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_fat = 'JOB'
  THEN
   -- faturamento de job
   SELECT cod_ext_fatur,
          emp_faturar_por_id,
          num_parcela,
          descricao
     INTO v_cod_ext_fatur,
          v_emp_fatur_id,
          v_num_parcela,
          v_descricao
     FROM faturamento
    WHERE faturamento_id = p_faturamento_id;
   --
   SELECT MAX(it.orcamento_id),
          nvl(SUM(ia.valor_fatura), 0)
     INTO v_orcamento_id,
          v_valor_fatura
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id;
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_orcam
     FROM item
    WHERE orcamento_id = v_orcamento_id;
   --
   /*
   IF v_valor_fatura <> v_valor_orcam THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O valor que está sendo faturado (' ||
                    moeda_mostrar(v_valor_fatura,'S') ||
                    ') não bate com o valor da estimativa de custos (' ||
                    moeda_mostrar(v_valor_orcam,'S') || ').';
      RAISE v_exception;
   END IF;
   */
   --
   v_id_jobone_fatura := to_number('11' || TRIM(to_char(p_faturamento_id, '0000000009')));
   v_id_jobone        := to_number('11' || TRIM(to_char(v_orcamento_id, '0000000009')));
   v_id_jobone_item   := to_char(v_num_parcela);
  ELSE
   -- faturamento de contrato
   SELECT cod_ext_fatur,
          emp_faturar_por_id,
          descricao
     INTO v_cod_ext_fatur,
          v_emp_fatur_id,
          v_descricao
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = p_faturamento_id;
   --
   SELECT MIN(pc.contrato_servico_id),
          MAX(pc.contrato_servico_id)
     INTO v_contrato_servico_id,
          v_contrato_servico_id_aux
     FROM parcela_fatur_ctr pf,
          parcela_contrato  pc
    WHERE pf.faturamento_ctr_id = p_faturamento_id
      AND pf.parcela_contrato_id = pc.parcela_contrato_id;
   --
   IF v_contrato_servico_id <> v_contrato_servico_id_aux
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O faturamento do contrato não pode misturar parcelas de produtos diferentes.';
    RAISE v_exception;
   END IF;
   --
   v_id_jobone_fatura := to_number('22' || TRIM(to_char(p_faturamento_id, '0000000009')));
   v_id_jobone        := to_number('22' || TRIM(to_char(v_contrato_servico_id, '0000000009')));
   v_id_jobone_item   := NULL;
   --
   FOR r_pa IN c_pa
   LOOP
    v_id_jobone_item := v_id_jobone_item || ',' || to_char(r_pa.parcela_contrato_id);
   END LOOP;
   --
   -- retira a primeira virgula
   v_id_jobone_item := substr(v_id_jobone_item, 2);
  END IF;
  --
  v_descricao := char_esp_protheus_retirar(v_descricao);
  v_descricao := substr(v_descricao, 1, 250);
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_empresa_filial
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_fatur_id;
  --
  IF v_empresa_filial IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa de faturamento ' ||
                 '(empresa/filial) não está definido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  IF p_cod_acao IN ('I', 'A') AND p_tipo_fat = 'JOB'
  THEN
   SELECT REPLACE(json_object('faturapedido' VALUE
                              json_object('id_jobone_fatura' VALUE to_number(v_id_jobone_fatura),
                                          'id_jobone' VALUE v_id_jobone,
                                          'id_jobone_item' VALUE nvl(v_id_jobone_item, ' '),
                                          'valor_faturamento' VALUE v_valor_fatura,
                                          'mensagem_nota' VALUE
                                          nvl(upper(acento_retirar(v_descricao)), 'ND'),
                                          'empresa_filial' VALUE nvl(v_empresa_filial, ' '))),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  ELSE
   -- contrato (nao manda valor do faturamento)
   SELECT REPLACE(json_object('faturapedido' VALUE
                              json_object('id_jobone_fatura' VALUE to_number(v_id_jobone_fatura),
                                          'id_jobone' VALUE v_id_jobone,
                                          'id_jobone_item' VALUE nvl(v_id_jobone_item, ' '),
                                          'mensagem_nota' VALUE
                                          nvl(upper(acento_retirar(v_descricao)), 'ND'),
                                          'empresa_filial' VALUE nvl(v_empresa_filial, ' '))),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  IF p_cod_acao IN ('E')
  THEN
   v_nota_fiscal       := substr(v_cod_ext_fatur, 1, 9);
   v_serie_nota_fiscal := substr(v_cod_ext_fatur, 10);
   --
   SELECT REPLACE(json_object('faturapedido' VALUE
                              json_object('id_jobone_fatura' VALUE to_number(v_id_jobone_fatura),
                                          'nota_fiscal' VALUE nvl(v_nota_fiscal, ' '),
                                          'serie_nota_fiscal' VALUE nvl(v_serie_nota_fiscal, ' '),
                                          'empresa_filial' VALUE nvl(v_empresa_filial, ' '))),
                  '" "',
                  '""')
     INTO v_xml_in
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  protheus_executar(p_sistema_externo_id,
                    p_empresa_id,
                    'FATURAMENTO',
                    p_cod_acao,
                    p_faturamento_id,
                    v_xml_in,
                    v_xml_out,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/cod_ext_fatur'))
     INTO v_cod_ext_fatur
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_fatur IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Protheus do faturamento.';
    RAISE v_exception;
   END IF;
   --
   IF p_tipo_fat = 'JOB'
   THEN
    UPDATE faturamento
       SET cod_ext_fatur = v_cod_ext_fatur
     WHERE faturamento_id = p_faturamento_id;
   ELSE
    UPDATE faturamento_ctr
       SET cod_ext_fatur = v_cod_ext_fatur
     WHERE faturamento_ctr_id = p_faturamento_id;
   END IF;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END faturamento_integrar;
 --
 --
 --
 PROCEDURE nf_saida_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 16/04/2021
  -- DESCRICAO: Procedure que trata o retorno de informacoes referentes a
  --  ordem de faturamento/NF saida (Alteracao, Exclusao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao         IN VARCHAR2,
  p_empresa_filial   IN VARCHAR2,
  p_id_jobone_fatura IN VARCHAR2,
  p_tipo_doc         IN VARCHAR2,
  p_num_doc          IN VARCHAR2,
  p_serie            IN VARCHAR2,
  p_chave_acesso     IN VARCHAR2,
  p_data_emissao     IN VARCHAR2,
  p_desc_servico     IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_nota_fiscal_sai_id nota_fiscal.nota_fiscal_id%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_tipo_doc_nf_id     nota_fiscal.tipo_doc_nf_id%TYPE;
  v_valor_fatura       nota_fiscal.valor_bruto%TYPE;
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_emp_fatur_id       faturamento.emp_faturar_por_id%TYPE;
  v_cod_ext_fatur      faturamento.cod_ext_fatur%TYPE;
  v_cliente_id         pessoa.pessoa_id%TYPE;
  v_job_id             job.job_id%TYPE;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_tipo_fatur         VARCHAR2(10);
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_cod_evento         VARCHAR2(20);
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  --
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'PROTHEUS_INPRESS';
  --
  IF v_sistema_externo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (PROTHEUS_INPRESS).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias do XML
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao NOT IN ('ALTERAR', 'EXCLUIR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_id_jobone_fatura) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'ID_JOBONE_FATURA não pode ter mais que 20 caracteres (' || p_id_jobone_fatura || ').';
   RAISE v_exception;
  END IF;
  --
  IF substr(p_id_jobone_fatura, 1, 2) = '11'
  THEN
   v_tipo_fatur     := 'JOB';
   v_faturamento_id := to_number(substr(p_id_jobone_fatura, 3));
  ELSIF substr(p_id_jobone_fatura, 1, 2) = '22'
  THEN
   v_tipo_fatur     := 'CONTRATO';
   v_faturamento_id := to_number(substr(p_id_jobone_fatura, 3));
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem de faturamento inválida - id_jobone_fatura (' || p_id_jobone_fatura || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_tipo_doc) > 5
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'TIPO_DOC não pode ter mais que 5 caracteres (' || p_tipo_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_doc) > 10
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'NUM_DOC não pode ter mais que 10 caracteres (' || p_num_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_serie) > 10
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'SERIE não pode ter mais que 10 caracteres (' || p_serie || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_chave_acesso) > 44
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CHAVE_ACESSO não pode ter mais que 44 caracteres (' || p_chave_acesso || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_servico) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'DESC_SERVICO não pode ter mais que 2000 caracteres (' || p_desc_servico || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_doc_nf_id)
    INTO v_tipo_doc_nf_id
    FROM tipo_doc_nf
   WHERE codigo = TRIM(p_tipo_doc)
     AND flag_nf_saida = 'S';
  --
  IF TRIM(p_tipo_doc) IS NULL OR v_tipo_doc_nf_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de documento inválido (' || p_tipo_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_num_doc) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número do documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_emissao) IS NULL OR data_protheus_validar(p_data_emissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão inválida (' || p_data_emissao || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_emissao := data_protheus_converter(p_data_emissao);
  --
  ------------------------------------------------------------
  -- NF de faturamento associado a estimativa de custos
  ------------------------------------------------------------
  IF v_tipo_fatur = 'JOB'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento
    WHERE faturamento_id = v_faturamento_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse faturamento de job não existe(' || p_id_jobone_fatura || ' / ' ||
                  to_char(v_faturamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT emp_faturar_por_id,
          nota_fiscal_sai_id,
          job_id,
          cliente_id
     INTO v_emp_fatur_id,
          v_nota_fiscal_sai_id,
          v_job_id,
          v_cliente_id
     FROM faturamento
    WHERE faturamento_id = v_faturamento_id;
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM item_fatur
    WHERE faturamento_id = v_faturamento_id;
  END IF; -- fim do IF v_tipo_fatur = 'JOB'
  --
  ------------------------------------------------------------
  -- NF de faturamento associado a servico do contrato
  ------------------------------------------------------------
  IF v_tipo_fatur = 'CONTRATO'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = v_faturamento_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse faturamento de contrato não existe(' || p_id_jobone_fatura || ' / ' ||
                  to_char(v_faturamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT emp_faturar_por_id,
          nota_fiscal_sai_id,
          cliente_id
     INTO v_emp_fatur_id,
          v_nota_fiscal_sai_id,
          v_cliente_id
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = v_faturamento_id;
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM parcela_fatur_ctr
    WHERE faturamento_ctr_id = v_faturamento_id;
  END IF; -- fim do IF v_tipo_fatur = 'CONTRATO'
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND pessoa_id = v_emp_fatur_id;
  --
  IF v_cod_ext_fatur IS NULL OR v_cod_ext_fatur <> p_empresa_filial
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da empresa de faturamento ' ||
                 '(empresa/filial) não bate com a da ordem de faturamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT empresa_id
    INTO v_empresa_id
    FROM pessoa
   WHERE pessoa_id = v_emp_fatur_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - EXCLUSAO
  ------------------------------------------------------------
  IF p_cod_acao = 'EXCLUIR'
  THEN
   v_cod_evento := 'EXCLUIR';
   --
   IF v_nota_fiscal_sai_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A ordem de faturamento não tem nota fiscal de saída (' || p_id_jobone_fatura || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_fatur = 'JOB'
   THEN
    UPDATE faturamento
       SET nota_fiscal_sai_id = NULL
     WHERE faturamento_id = v_faturamento_id;
   ELSE
    UPDATE faturamento_ctr
       SET nota_fiscal_sai_id = NULL
     WHERE faturamento_ctr_id = v_faturamento_id;
   END IF;
   --
   DELETE FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM imposto_nota
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM item_nota
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM nota_fiscal
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - INCLUIR/ALTERAR
  ------------------------------------------------------------
  IF p_cod_acao = 'ALTERAR' AND v_nota_fiscal_sai_id IS NULL
  THEN
   v_cod_evento := 'INCLUIR';
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM nota_fiscal nf
    WHERE nf.emp_emissora_id = v_emp_fatur_id
      AND nf.tipo_doc_nf_id = v_tipo_doc_nf_id
      AND nf.num_doc = TRIM(p_num_doc)
      AND nvl(nf.serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
   --
   IF v_qt > 0
   THEN
    -- a NF de saida enviada ja existe
    p_erro_cod := '90000';
    p_erro_msg := 'Esse documento já existe (' || to_char(v_emp_fatur_id) || ' ' ||
                  TRIM(p_tipo_doc || ' ' || p_num_doc || ' ' || p_serie) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_nota_fiscal.nextval
     INTO v_nota_fiscal_sai_id
     FROM dual;
   --
   INSERT INTO nota_fiscal
    (nota_fiscal_id,
     emp_emissora_id,
     cliente_id,
     job_id,
     tipo_ent_sai,
     tipo_doc_nf_id,
     num_doc,
     serie,
     chave_acesso,
     data_entrada,
     data_emissao,
     valor_bruto,
     valor_mao_obra,
     desc_servico,
     status)
   VALUES
    (v_nota_fiscal_sai_id,
     v_emp_fatur_id,
     v_cliente_id,
     v_job_id,
     'S',
     v_tipo_doc_nf_id,
     TRIM(p_num_doc),
     TRIM(p_serie),
     TRIM(p_chave_acesso),
     SYSDATE,
     v_data_emissao,
     v_valor_fatura,
     0,
     substr(TRIM(p_desc_servico), 1, 2000),
     'CONC');
   --
   IF v_tipo_fatur = 'JOB'
   THEN
    UPDATE faturamento
       SET nota_fiscal_sai_id = v_nota_fiscal_sai_id
     WHERE faturamento_id = v_faturamento_id;
   ELSE
    UPDATE faturamento_ctr
       SET nota_fiscal_sai_id = v_nota_fiscal_sai_id
     WHERE faturamento_ctr_id = v_faturamento_id;
   END IF;
  END IF; -- fim do ALTERAR sem NF saida
  --
  IF p_cod_acao = 'ALTERAR' AND v_nota_fiscal_sai_id IS NOT NULL
  THEN
   v_cod_evento := 'ALTERAR';
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM nota_fiscal nf
    WHERE nf.emp_emissora_id = v_emp_fatur_id
      AND nf.tipo_doc_nf_id = v_tipo_doc_nf_id
      AND nf.num_doc = TRIM(p_num_doc)
      AND nvl(nf.serie, 'XXX') = nvl(TRIM(p_serie), 'XXX')
      AND nota_fiscal_id <> v_nota_fiscal_sai_id;
   --
   IF v_qt > 0
   THEN
    -- a NF de saida enviada ja existe, associada a outra ordem
    p_erro_cod := '90000';
    p_erro_msg := 'Esse documento já existe (' || to_char(v_emp_fatur_id) || ' ' ||
                  TRIM(p_tipo_doc || ' ' || p_num_doc || ' ' || p_serie) || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE nota_fiscal
      SET emp_emissora_id = v_emp_fatur_id,
          cliente_id      = v_cliente_id,
          job_id          = v_job_id,
          tipo_ent_sai    = 'S',
          tipo_doc_nf_id  = v_tipo_doc_nf_id,
          num_doc         = TRIM(p_num_doc),
          serie           = TRIM(p_serie),
          chave_acesso    = TRIM(p_chave_acesso),
          data_entrada    = SYSDATE,
          data_emissao    = v_data_emissao,
          valor_bruto     = v_valor_fatura,
          desc_servico    = substr(TRIM(p_desc_servico), 1, 2000),
          status          = 'CONC'
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
  END IF; -- fim do ALTERAR com NF saida
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'Empresa/Filial: ' || p_empresa_filial || ' - NF Saída: ' || TRIM(p_num_doc) ||
                      TRIM(p_serie) || ' - ordem: ' || to_char(v_faturamento_id);
  v_compl_histor   := 'Integração Protheus';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'NOTA_FISCAL',
                   v_cod_evento,
                   v_identif_objeto,
                   v_nota_fiscal_sai_id,
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
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END nf_saida_processar;
 --
 --
 --
 PROCEDURE tipo_produto_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 06/01/2021
  -- DESCRICAO: subrotina que replica dados de TIPO_PRODUTO na empresa.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_cod_ext_produto    IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_tipo_produto_id     tipo_produto.tipo_produto_id%TYPE;
  v_cod_ext_produto     tipo_produto.cod_ext_produto%TYPE;
  v_cod_ext_produto_aux tipo_produto.cod_ext_produto%TYPE;
  v_flag_sistema        tipo_produto.flag_sistema%TYPE;
  v_empresa             empresa.nome%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_cod_evento          VARCHAR2(40);
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT nome
    INTO v_empresa
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  SELECT MAX(tipo_produto_id)
    INTO v_tipo_produto_id
    FROM tipo_produto
   WHERE empresa_id = p_empresa_id
     AND cod_ext_produto = p_cod_ext_produto;
  --
  IF v_tipo_produto_id IS NULL
  THEN
   SELECT MAX(tipo_produto_id),
          MAX(cod_ext_produto)
     INTO v_tipo_produto_id,
          v_cod_ext_produto_aux
     FROM tipo_produto
    WHERE TRIM(nome) = TRIM(p_nome)
      AND empresa_id = p_empresa_id;
   --
   IF v_cod_ext_produto_aux <> p_cod_ext_produto
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O produto ' || TRIM(p_nome) || ' já existe na empresa ' || v_empresa ||
                  ' com o código ' || v_cod_ext_produto_aux ||
                  ' que não bate com o código enviado (' || p_cod_ext_produto || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF p_operacao IN ('INCLUIR', 'ALTERAR')
  THEN
   IF v_tipo_produto_id IS NULL
   THEN
    v_cod_evento := 'INCLUIR';
    --
    SELECT seq_tipo_produto.nextval
      INTO v_tipo_produto_id
      FROM dual;
    --
    INSERT INTO tipo_produto
     (empresa_id,
      tipo_produto_id,
      nome,
      cod_ext_produto,
      flag_ativo,
      flag_sistema /*,
                  flag_midia_online,
                  flag_midia_offline*/)
    VALUES
     (p_empresa_id,
      v_tipo_produto_id,
      TRIM(p_nome),
      TRIM(p_cod_ext_produto),
      'S',
      'N' /*,
                  'N',
                  'N'*/);
   ELSE
    v_cod_evento := 'ALTERAR';
    --
    UPDATE tipo_produto
       SET nome            = TRIM(p_nome),
           cod_ext_produto = p_cod_ext_produto
     WHERE tipo_produto_id = v_tipo_produto_id;
   END IF;
  END IF; -- fim do IF p_operacao IN ('INCLUIR','ALTERAR')
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
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF p_operacao = 'EXCLUIR' AND v_tipo_produto_id IS NOT NULL
  THEN
   v_cod_evento := 'EXCLUIR';
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto está sendo referenciado por algum item na empresa ' || v_empresa || '(' ||
                  p_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto está sendo referenciado por algum Workflow ou Task na empresa ' ||
                  v_empresa || '(' || p_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_sistema
     INTO v_flag_sistema
     FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_flag_sistema = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Produto pertencente ao sistema não pode ser excluído (' || p_nome || ').';
    RAISE v_exception;
   END IF;
   --
   --
   DELETE FROM metadado
    WHERE objeto_id = v_tipo_produto_id
      AND tipo_objeto = 'TIPO_PRODUTO'
      AND empresa_id = p_empresa_id;
   --
   DELETE FROM tipo_prod_tipo_os
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   DELETE FROM tipo_produto_var
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   DELETE FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := 'Integração Protheus';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   v_cod_evento,
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
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END tipo_produto_atualizar;
 --
 --
 --
 PROCEDURE tipo_produto_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 07/01/2021
  -- DESCRICAO: Procedure que trata o recebimento de informacoes referentes a
  --  integração de TIPO_PRODUTO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao        IN VARCHAR2,
  p_nome            IN VARCHAR2,
  p_cod_ext_produto IN VARCHAR2,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_tipo_produto_id    tipo_produto.tipo_produto_id%TYPE;
  v_operacao           VARCHAR2(10);
  --
  CURSOR c_em IS
   SELECT sp.empresa_id
     FROM sist_ext_ponto_int sp,
          ponto_integracao   pi
    WHERE sp.sistema_externo_id = v_sistema_externo_id
      AND sp.ponto_integracao_id = pi.ponto_integracao_id
      AND pi.codigo = decode(p_cod_acao,
                             'I',
                             'TIPO_PRODUTO_ADICIONAR',
                             'A',
                             'TIPO_PRODUTO_ATUALIZAR',
                             'E',
                             'TIPO_PRODUTO_EXCLUIR');
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'PROTHEUS_INPRESS';
  --
  IF v_sistema_externo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (PROTHEUS_INPRESS).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF p_cod_acao IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_ext_produto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I'
  THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A'
  THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E'
  THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  FOR r_em IN c_em
  LOOP
   it_protheus_pkg.tipo_produto_atualizar(v_usuario_sessao_id,
                                          v_sistema_externo_id,
                                          r_em.empresa_id,
                                          v_operacao,
                                          TRIM(p_nome),
                                          TRIM(p_cod_ext_produto),
                                          p_erro_cod,
                                          p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: erro na integração de tipo de produto. ' || p_erro_msg;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na integração de tipo de produto. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
   ROLLBACK;
 END tipo_produto_processar;
 --
 --
 --
 PROCEDURE protheus_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 11/04/2013
  -- DESCRICAO: Subrotina que executa a chamada de webservices no sistema PROTHEUS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_objeto         IN VARCHAR2,
  p_cod_acao           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_xml_in             IN CLOB,
  p_xml_out            OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT CLOB
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml_log_id xml_log.xml_log_id%TYPE;
  v_status_ret VARCHAR2(20);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  --
  IF TRIM(p_cod_objeto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'JOBONE', 'PROTHEUS', p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  IF p_cod_objeto = 'PESSOA_CLI'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pessoaClienteIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'PESSOA_FOR'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pessoaFornecedorIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'ORCAMENTO'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pedidoVendaIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'CONTRATO'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pedidoVendaIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'NOTA_FISCAL_ENTRADA'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'notaFiscalEntradaIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'FATURAMENTO'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'faturamentoIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_erro_msg) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   RAISE v_exception;
  END IF;
  --
  -- recupera o status retornado
  SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno/Status'))
    INTO v_status_ret
    FROM (SELECT xmltype(p_xml_out) AS xml_out
            FROM dual);
  --
  v_status_ret := TRIM(upper(v_status_ret));
  --
  IF v_status_ret = 'ERROR'
  THEN
   SELECT MAX(extractvalue(xml_out, '/Protheus/Retorno//Message'))
     INTO p_erro_msg
     FROM (SELECT xmltype(p_xml_out) AS xml_out
             FROM dual);
   --
   p_erro_cod := '90000';
   RAISE v_exception;
  ELSIF v_status_ret IS NULL OR v_status_ret <> 'T'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status do xml de retorno não encontrado.';
   RAISE v_exception;
  END IF;
  --
  log_concluir(v_xml_log_id, p_objeto_id, p_xml_out);
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'PROTHEUS: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'PROTHEUS - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END protheus_executar;
 --
 --
 FUNCTION uuid_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/04/2013
  -- DESCRICAO: retorna o UUID formatado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  RETURN VARCHAR2 AS
  v_uuid    VARCHAR2(60);
  v_retorno VARCHAR2(60);
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT rawtohex(sys_guid())
    INTO v_uuid
    FROM dual;
  --
  /*
  v_retorno := SUBSTR(v_uuid,1,8) || '-' ||
               SUBSTR(v_uuid,9,4) || '-' ||
               SUBSTR(v_uuid,13,4) || '-' ||
               SUBSTR(v_uuid,17,4) || '-' ||
               SUBSTR(v_uuid,21);
  v_retorno := LOWER(v_retorno);*/
  --
  v_retorno := v_uuid;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END uuid_retornar;
 --
 --
 --
 FUNCTION data_protheus_converter
 -----------------------------------------------------------------------
  --   DATA_PROTHEUS_CONVERTER
  --
  --   Descricao: funcao que converte um string contendo uma data no
  --   formato 'DDMMYYYY'.
  -----------------------------------------------------------------------
 (p_data IN VARCHAR2) RETURN DATE IS
  --
  v_data DATE;
  --
 BEGIN
  v_data := NULL;
  v_data := to_date(p_data, 'yyyymmdd');
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data;
 END data_protheus_converter;
 --
 --
 --
 FUNCTION data_protheus_validar
 -----------------------------------------------------------------------
  --   DATA_PROTHEUS_VALIDAR
  --
  --   Descricao: funcao que consiste um string contendo uma data no
  --   formato 'DDMMYYYY' do ADN Net. Retorna '1' caso o string seja
  --   uma data valida, e '0' caso nao seja. Para um string igual a NULL,
  --   retorna '1'.
  -----------------------------------------------------------------------
 (p_data IN VARCHAR2) RETURN INTEGER IS
  --
  v_ok   INTEGER;
  v_data DATE;
  v_ano  INTEGER;
  --
 BEGIN
  v_ok   := 0;
  v_data := to_date(p_data, 'yyyymmdd');
  IF rtrim(p_data) IS NOT NULL
  THEN
   v_ano := to_number(to_char(v_data, 'yyyy'));
   IF v_ano > 1000
   THEN
    v_ok := 1;
   END IF;
  ELSE
   v_ok := 1;
  END IF;
  RETURN v_ok;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END data_protheus_validar;
 --
 --
 --
 FUNCTION numero_protheus_converter
 -----------------------------------------------------------------------
  --   NUMERO_PROTHEUS_CONVERTER
  --
  --   Descricao: função que converte um string previamente validado
  --   em numero. O string pdeve estar tanto no formato
  --   '99999999999999999999.99999'
  -----------------------------------------------------------------------
 (p_numero IN VARCHAR2) RETURN NUMBER IS
  v_ok          INTEGER;
  v_numero      NUMBER;
  v_numero_char VARCHAR2(30);
  --
 BEGIN
  v_numero      := NULL;
  v_numero_char := rtrim(REPLACE(p_numero, ',', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
  --
  RETURN v_numero;
 EXCEPTION
  WHEN OTHERS THEN
   v_numero := 99999999;
   RETURN v_numero;
 END numero_protheus_converter;
 --
 --
 --
 FUNCTION numero_protheus_validar
 -----------------------------------------------------------------------
  --   NUMERO_PROTHEUS_VALIDAR
  --
  --   Descricao: funcao que consiste uma string nos seguintes
  --   formatos moeda '99999999999999999999.99'.
  --   Retorna 1 caso o string seja um valor valido, 0 caso nao seja.
  --   Para um string igual a NULL, retorna 1.
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
  IF instr(p_numero, ',') > 0
  THEN
   RETURN v_ok;
  END IF;
  --
  v_numero_char := rtrim(REPLACE(p_numero, ',', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
  v_ok     := 1;
  --
  RETURN v_ok;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END numero_protheus_validar;
 --
--
END; -- IT_PROTHEUS_PKG

/
