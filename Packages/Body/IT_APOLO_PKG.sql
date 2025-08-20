--------------------------------------------------------
--  DDL for Package Body IT_APOLO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_APOLO_PKG" IS
 --
 v_xml_doc     VARCHAR2(100) := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
 v_xml_doc_ret VARCHAR2(100) := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
 --  v_xml_doc_ret         VARCHAR2(100):= '<?xml version="1.0" encoding="UTF-8" ?>';--
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
  -- Silvia            20/06/2017  Novo parametro objeto_id
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
  IF p_xml_in IS NOT NULL THEN
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
  -- Silvia            20/06/2017  Novo parametro objeto_id
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
  IF p_xml_out IS NOT NULL THEN
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
 FUNCTION char_esp_apolo_retirar
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
 END char_esp_apolo_retirar;
 --
 --
 --
 PROCEDURE xml_env_cabec_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que gera o xml do cabecalho de envio ao sistema externo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_emp_resp_id        IN job.emp_resp_id%TYPE,
  p_processo           IN VARCHAR2,
  p_xml_cabecalho      OUT xmltype,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_grupo           VARCHAR2(10);
  v_data_hora       VARCHAR2(40);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- monta o cabecalho padrao
  ------------------------------------------------------------
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_ext_empresa
    FROM empresa_sist_ext
   WHERE empresa_id = p_empresa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_resp_id, 0) > 0 THEN
   -- ao inves da empresa do multi-agencia, usa no cabecalho o codigo da empresa
   -- (pessoa) responsavel pelo job.
   SELECT MAX(cod_ext_resp)
     INTO v_cod_ext_empresa
     FROM empr_resp_sist_ext
    WHERE pessoa_id = p_emp_resp_id
      AND sistema_externo_id = p_sistema_externo_id;
   --
   IF v_cod_ext_empresa IS NULL THEN
    SELECT MAX(cod_ext_fatur)
      INTO v_cod_ext_empresa
      FROM empr_fatur_sist_ext
     WHERE pessoa_id = p_emp_resp_id
       AND sistema_externo_id = p_sistema_externo_id;
    --
    IF v_cod_ext_empresa IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Código externo da empresa responsável/faturamento pelo job não definido.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  v_grupo           := substr(v_cod_ext_empresa, 1, 2);
  v_cod_ext_empresa := substr(v_cod_ext_empresa, 3);
  v_data_hora       := to_char(SYSDATE, 'yyyy-mm-dd') || ' ' || to_char(SYSDATE, 'hh24:mi:ss');
  --
  SELECT xmlconcat(xmlelement("GlobalFunctionCode", 'EAI'),
                   xmlelement("DocVersion", '1.0'),
                   xmlelement("DocDateTime", v_data_hora),
                   xmlelement("DocCompany", v_grupo),
                   xmlelement("DocBranch", v_cod_ext_empresa),
                   xmlelement("DocName", ''),
                   xmlelement("DocFederalID", '0'),
                   xmlelement("DocType", '1'))
    INTO p_xml_cabecalho
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_APOLO_PKG(ret_cabec): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_APOLO_PKG(ret_cabec): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END xml_env_cabec_gerar;
 --
 --
 --
 PROCEDURE xml_ret_cabec_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que gera o xml do cabecalho de retorno ao sistema externo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_processo           IN VARCHAR2,
  p_xml_cabecalho      OUT xmltype,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_data_hora       VARCHAR2(40);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- monta o cabecalho padrao
  ------------------------------------------------------------
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_ext_empresa
    FROM empresa_sist_ext
   WHERE empresa_id = p_empresa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido.';
   RAISE v_exception;
  END IF;
  --
  v_data_hora := to_char(SYSDATE, 'yyyy-mm-dd') || ' ' || to_char(SYSDATE, 'hh24:mi:ss');
  --
  SELECT xmlagg(xmlelement("cabecalho",
                           xmlelement("empresa", v_cod_ext_empresa),
                           xmlelement("sistema", 'JOBONE'),
                           xmlelement("processo", p_processo),
                           xmlelement("data", v_data_hora)))
    INTO p_xml_cabecalho
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_APOLO_PKG(ret_cabec): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_APOLO_PKG(ret_cabec): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END xml_ret_cabec_gerar;
 --
 --
 --
 PROCEDURE xml_ret_msg_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que gera o xml da mensagem de retorno ao sistema externo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_retorno        IN VARCHAR2,
  p_processo           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_mensagem           IN VARCHAR2,
  p_xml_resposta       OUT xmltype,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- monta o cabecalho padrao
  ------------------------------------------------------------
  --
  IF p_processo = 'PESSOA' THEN
   SELECT xmlagg(xmlelement("retorno",
                            xmlelement("pessoa_id", p_objeto_id),
                            xmlelement("cod_erro", p_cod_retorno),
                            xmlelement("msg_erro", p_mensagem)))
     INTO p_xml_resposta
     FROM dual;
  ELSIF p_processo = 'TIPO_PRODUTO' THEN
   SELECT xmlagg(xmlelement("retorno",
                            xmlelement("tipo_produto_id", p_objeto_id),
                            xmlelement("cod_erro", p_cod_retorno),
                            xmlelement("msg_erro", p_mensagem)))
     INTO p_xml_resposta
     FROM dual;
  ELSE
   SELECT xmlagg(xmlelement("retorno",
                            xmlelement("objeto_id", p_objeto_id),
                            xmlelement("cod_erro", p_cod_retorno),
                            xmlelement("msg_erro", p_mensagem)))
     INTO p_xml_resposta
     FROM dual;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_APOLO_PKG(ret_msg): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_APOLO_PKG(ret_msg): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END xml_ret_msg_gerar;
 --
 --
 --
 PROCEDURE xml_retorno_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: Subrotina que gera o xml de retorno ao sistema externo (cabecalho+mensagem).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_retorno        IN VARCHAR2,
  p_processo           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_mensagem           IN VARCHAR2,
  p_xml_retorno        OUT VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_xml_retorno     xmltype;
  v_xml_cabecalho   xmltype;
  v_xml_resposta    xmltype;
  v_mensagem        VARCHAR2(1000);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- monta o cabecalho padrao
  ------------------------------------------------------------
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_ext_empresa
    FROM empresa_sist_ext
   WHERE empresa_id = p_empresa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido.';
   RAISE v_exception;
  END IF;
  --
  xml_ret_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      p_processo,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  v_mensagem := upper(acento_retirar(p_mensagem));
  --
  xml_ret_msg_gerar(p_sistema_externo_id,
                    p_empresa_id,
                    p_cod_retorno,
                    p_processo,
                    p_objeto_id,
                    v_mensagem,
                    v_xml_resposta,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_resposta))
    INTO v_xml_retorno
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc_ret || v_xml_retorno.getclobval()
    INTO p_xml_retorno
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_APOLO_PKG(retorno): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_APOLO_PKG(retorno): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END xml_retorno_gerar;
 --
 --
 --
 PROCEDURE pessoa_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do APOLO referentes a
  --  integração de PESSOA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_cod_agencia IN VARCHAR2,
  p_cod_acao    IN VARCHAR2,
  p_xml_in      IN CLOB,
  p_xml_out     OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_erro_cod           VARCHAR2(20);
  v_erro_msg           VARCHAR2(200);
  v_xml_in             xmltype;
  v_xml_retorno        CLOB;
  v_xml_log_id         xml_log.xml_log_id%TYPE;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_tipo_pessoa        tipo_pessoa.codigo%TYPE;
  v_pessoa_id          pessoa.pessoa_id%TYPE;
  v_caminho_campos     VARCHAR2(100);
  v_operacao           VARCHAR2(10);
  v_sistema            VARCHAR2(40);
  v_processo           VARCHAR2(40);
  v_processo_xml       VARCHAR2(40);
  v_cod_ext_pessoa     VARCHAR2(100);
  v_apelido            VARCHAR2(100);
  v_nome               VARCHAR2(200);
  v_flag_pessoa_jur    VARCHAR2(100);
  v_flag_pessoa_ex     VARCHAR2(100);
  v_cnpj               VARCHAR2(100);
  v_inscr_estadual     VARCHAR2(100);
  v_inscr_municipal    VARCHAR2(100);
  v_inscr_inss         VARCHAR2(100);
  v_cpf                VARCHAR2(100);
  v_rg                 VARCHAR2(100);
  v_rg_org_exp         VARCHAR2(100);
  v_rg_data_exp        VARCHAR2(100);
  v_rg_uf              VARCHAR2(100);
  v_data_nasc          VARCHAR2(100);
  v_endereco           VARCHAR2(200);
  v_num_ender          VARCHAR2(100);
  v_compl_ender        VARCHAR2(100);
  v_zona               VARCHAR2(100);
  v_bairro             VARCHAR2(200);
  v_cep                VARCHAR2(100);
  v_cidade             VARCHAR2(200);
  v_uf                 VARCHAR2(100);
  v_pais               VARCHAR2(200);
  v_ddd_telefone       VARCHAR2(100);
  v_num_telefone       VARCHAR2(100);
  v_num_ramal          VARCHAR2(100);
  v_ddd_fax            VARCHAR2(100);
  v_num_fax            VARCHAR2(100);
  v_ddd_celular        VARCHAR2(100);
  v_num_celular        VARCHAR2(100);
  v_website            VARCHAR2(200);
  v_email              VARCHAR2(200);
  v_tipo_conta         VARCHAR2(100);
  v_cod_banco          VARCHAR2(100);
  v_num_agencia        VARCHAR2(100);
  v_num_conta          VARCHAR2(100);
  v_nome_titular       VARCHAR2(200);
  v_cnpj_cpf_titular   VARCHAR2(100);
  --
  CURSOR c_em IS
   SELECT em.empresa_id,
          em.nome
     FROM empresa          em,
          empresa_sist_ext se
    WHERE em.flag_ativo = 'S'
      AND em.empresa_id = se.empresa_id
      AND sistema_externo_id = v_sistema_externo_id;
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  v_processo := 'PESSOA';
  --
  IF TRIM(p_cod_acao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_xml_in IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'XML não fornecido.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'APOLO', 'JOBONE', 'PESSOA', p_cod_acao, NULL, p_xml_in);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'APOLO_ESFERABR';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (APOLO_ESFERA).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa
   WHERE codigo = p_cod_agencia;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da agência não encontrado (' || p_cod_agencia || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- extracao do cabecalho
  ------------------------------------------------------------
  --
  SELECT xmltype(TRIM(p_xml_in))
    INTO v_xml_in
    FROM dual;
  --
  SELECT TRIM(extractvalue(v_xml_in, '/mensagem/cabecalho/sistema')),
         TRIM(extractvalue(v_xml_in, '/mensagem/cabecalho/processo'))
    INTO v_sistema,
         v_processo_xml
    FROM dual;
  --
  v_sistema      := upper(v_sistema);
  v_processo_xml := upper(v_processo_xml);
  --
  IF v_sistema IS NULL OR v_sistema <> 'JOBONE' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do sistema inválido (' || v_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_processo_xml IS NULL OR v_processo_xml <> v_processo THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do processo inválido (' || v_processo_xml || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- extracao dos detalhes da pessoa
  ------------------------------------------------------------
  v_caminho_campos := '/mensagem/conteudo/';
  --
  SELECT TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cod_externo')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'apelido')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'nome')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'flag_pessoa_jur')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'flag_pessoa_ex')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cnpj')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'inscr_estadual')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'inscr_municipal')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'inscr_inss')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cpf')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'rg')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'rg_org_exp')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'rg_data_exp')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'rg_uf')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'data_nasc')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'endereco')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_ender')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'compl_ender')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'zona')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'bairro')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cep')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cidade')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'uf')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'pais')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'ddd_telefone')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_telefone')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_ramal')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'ddd_fax')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_fax')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'ddd_celular')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_celular')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'website')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'email')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'tipo_conta')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cod_banco')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_agencia')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'num_conta')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'nome_titular')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cnpj_cpf_titular'))
    INTO v_cod_ext_pessoa,
         v_apelido,
         v_nome,
         v_flag_pessoa_jur,
         v_flag_pessoa_ex,
         v_cnpj,
         v_inscr_estadual,
         v_inscr_municipal,
         v_inscr_inss,
         v_cpf,
         v_rg,
         v_rg_org_exp,
         v_rg_data_exp,
         v_rg_uf,
         v_data_nasc,
         v_endereco,
         v_num_ender,
         v_compl_ender,
         v_zona,
         v_bairro,
         v_cep,
         v_cidade,
         v_uf,
         v_pais,
         v_ddd_telefone,
         v_num_telefone,
         v_num_ramal,
         v_ddd_fax,
         v_num_fax,
         v_ddd_celular,
         v_num_celular,
         v_website,
         v_email,
         v_tipo_conta,
         v_cod_banco,
         v_num_agencia,
         v_num_conta,
         v_nome_titular,
         v_cnpj_cpf_titular
    FROM dual;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  FOR r_em IN c_em
  LOOP
   -- loop por empresa ativa do schema, associada a esse sistema externo
   v_tipo_pessoa := 'CLIENTE';
   --
   it_apolo_pkg.pessoa_atualizar(v_usuario_sessao_id,
                                 v_sistema_externo_id,
                                 r_em.empresa_id,
                                 v_operacao,
                                 v_tipo_pessoa,
                                 v_cod_ext_pessoa,
                                 v_apelido,
                                 v_nome,
                                 v_flag_pessoa_jur,
                                 v_flag_pessoa_ex,
                                 v_cnpj,
                                 v_inscr_estadual,
                                 v_inscr_municipal,
                                 v_inscr_inss,
                                 v_cpf,
                                 v_rg,
                                 v_rg_org_exp,
                                 v_rg_data_exp,
                                 v_rg_uf,
                                 v_data_nasc,
                                 v_endereco,
                                 v_num_ender,
                                 v_compl_ender,
                                 v_zona,
                                 v_bairro,
                                 v_cep,
                                 v_cidade,
                                 v_uf,
                                 v_pais,
                                 v_ddd_telefone,
                                 v_num_telefone,
                                 v_num_ramal,
                                 v_ddd_fax,
                                 v_num_fax,
                                 v_ddd_celular,
                                 v_num_celular,
                                 v_website,
                                 v_email,
                                 v_tipo_conta,
                                 v_cod_banco,
                                 v_num_agencia,
                                 v_num_conta,
                                 v_nome_titular,
                                 v_cnpj_cpf_titular,
                                 v_pessoa_id,
                                 p_erro_cod,
                                 p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    p_erro_msg := p_erro_msg || ' (' || r_em.nome || ')';
    RAISE v_exception;
   END IF;
   --
   v_tipo_pessoa := 'FORNECEDOR';
   --
   it_apolo_pkg.pessoa_atualizar(v_usuario_sessao_id,
                                 v_sistema_externo_id,
                                 r_em.empresa_id,
                                 v_operacao,
                                 v_tipo_pessoa,
                                 v_cod_ext_pessoa,
                                 v_apelido,
                                 v_nome,
                                 v_flag_pessoa_jur,
                                 v_flag_pessoa_ex,
                                 v_cnpj,
                                 v_inscr_estadual,
                                 v_inscr_municipal,
                                 v_inscr_inss,
                                 v_cpf,
                                 v_rg,
                                 v_rg_org_exp,
                                 v_rg_data_exp,
                                 v_rg_uf,
                                 v_data_nasc,
                                 v_endereco,
                                 v_num_ender,
                                 v_compl_ender,
                                 v_zona,
                                 v_bairro,
                                 v_cep,
                                 v_cidade,
                                 v_uf,
                                 v_pais,
                                 v_ddd_telefone,
                                 v_num_telefone,
                                 v_num_ramal,
                                 v_ddd_fax,
                                 v_num_fax,
                                 v_ddd_celular,
                                 v_num_celular,
                                 v_website,
                                 v_email,
                                 v_tipo_conta,
                                 v_cod_banco,
                                 v_num_agencia,
                                 v_num_conta,
                                 v_nome_titular,
                                 v_cnpj_cpf_titular,
                                 v_pessoa_id,
                                 p_erro_cod,
                                 p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    p_erro_msg := p_erro_msg || ' (' || r_em.nome || ')';
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao do xml de retorno
  ------------------------------------------------------------
  xml_retorno_gerar(v_sistema_externo_id,
                    v_empresa_id,
                    '00000',
                    v_processo,
                    v_pessoa_id,
                    NULL,
                    v_xml_retorno,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao do log
  ------------------------------------------------------------
  log_concluir(v_xml_log_id, v_pessoa_id, v_xml_retorno);
  --
  p_xml_out := v_xml_retorno;
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: ' || p_erro_msg;
   --
   xml_retorno_gerar(v_sistema_externo_id,
                     v_empresa_id,
                     p_erro_cod,
                     v_processo,
                     v_pessoa_id,
                     p_erro_msg,
                     v_xml_retorno,
                     v_erro_cod,
                     v_erro_msg);
   --
   log_concluir(v_xml_log_id, v_pessoa_id, v_xml_retorno);
   --
   p_xml_out := v_xml_retorno;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na geração do arquivo de retorno. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
   ROLLBACK;
 END pessoa_processar;
 --
 --
 --
 PROCEDURE pessoa_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 17/04/2013
  -- DESCRICAO: subrotina que consiste e atualiza PESSOA.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/11/2015  Mantem dados bancarios do JobOne em caso de atualizacao
  --                               de pessoa.
  -- Silvia            03/06/2016  LOCK TABLE em pessoa antes da inclusao
  -- Silvia            31/05/2017  Formatacao da data de nascimento (YYYYMMDD)
  -- Silvia            22/11/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_tipo_pessoa        IN VARCHAR2,
  p_cod_ext_pessoa     IN VARCHAR2,
  p_apelido            IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_flag_pessoa_jur    IN VARCHAR2,
  p_flag_pessoa_ex     IN VARCHAR2,
  p_cnpj               IN VARCHAR2,
  p_inscr_estadual     IN VARCHAR2,
  p_inscr_municipal    IN VARCHAR2,
  p_inscr_inss         IN VARCHAR2,
  p_cpf                IN VARCHAR2,
  p_rg                 IN VARCHAR2,
  p_rg_org_exp         IN VARCHAR2,
  p_rg_data_exp        IN VARCHAR2,
  p_rg_uf              IN VARCHAR2,
  p_data_nasc          IN VARCHAR2,
  p_endereco           IN VARCHAR2,
  p_num_ender          IN VARCHAR2,
  p_compl_ender        IN VARCHAR2,
  p_zona               IN VARCHAR2,
  p_bairro             IN VARCHAR2,
  p_cep                IN VARCHAR2,
  p_cidade             IN VARCHAR2,
  p_uf                 IN VARCHAR2,
  p_pais               IN VARCHAR2,
  p_ddd_telefone       IN VARCHAR2,
  p_num_telefone       IN VARCHAR2,
  p_num_ramal          IN VARCHAR2,
  p_ddd_fax            IN VARCHAR2,
  p_num_fax            IN VARCHAR2,
  p_ddd_celular        IN VARCHAR2,
  p_num_celular        IN VARCHAR2,
  p_website            IN VARCHAR2,
  p_email              IN VARCHAR2,
  p_tipo_conta         IN VARCHAR2,
  p_cod_banco          IN VARCHAR2,
  p_num_agencia        IN VARCHAR2,
  p_num_conta          IN VARCHAR2,
  p_nome_titular       IN VARCHAR2,
  p_cnpj_cpf_titular   IN VARCHAR2,
  p_pessoa_id          OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_exception                  EXCEPTION;
  v_pessoa_id                  pessoa.pessoa_id%TYPE;
  v_fi_banco_id                pessoa.fi_banco_id%TYPE;
  v_cnpj                       pessoa.cnpj%TYPE;
  v_cpf                        pessoa.cpf%TYPE;
  v_obs                        pessoa.obs%TYPE;
  v_pais                       pessoa.pais%TYPE;
  v_flag_sem_docum             pessoa.flag_sem_docum%TYPE;
  v_emp_resp_pdr_id            pessoa.emp_resp_pdr_id%TYPE;
  v_cnpj_cpf_titular           pessoa.cnpj_cpf_titular%TYPE;
  v_tipo_pessoa_id             tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_est_id         tipo_pessoa.tipo_pessoa_id%TYPE;
  v_perc_imposto               fi_tipo_imposto_pessoa.perc_imposto%TYPE;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_flag_pessoa_impostos_zerar VARCHAR2(10);
  v_num_agencia                VARCHAR2(40);
  v_num_conta                  VARCHAR2(40);
  v_cod_evento                 VARCHAR2(40);
  v_lbl_jobs                   VARCHAR2(100);
  v_xml_atual                  CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_est_id
    FROM tipo_pessoa
   WHERE codigo = 'ESTRANGEIRO';
  --
  IF v_tipo_pessoa_est_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de pessoa ESTRANGEIRO não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_id
    FROM tipo_pessoa
   WHERE codigo = p_tipo_pessoa;
  --
  IF v_tipo_pessoa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de pessoa inválido (' || p_tipo_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_ext_pessoa) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código Apolo da pessoa é obrigatório (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_ext_pessoa) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código Apolo da pessoa não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_flag_pessoa_jur, 'Z') NOT IN ('S', 'N') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Indicação de pessoa física/jurídica inválida (' || p_flag_pessoa_jur || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_flag_pessoa_ex, 'Z') NOT IN ('S', 'N') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Indicação de pessoa no estrangeiro inválida (' || p_flag_pessoa_ex || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_apelido) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome curto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_apelido) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome curto não pode ter mais que 100 caracteres (' || p_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social não pode ter mais que 100 caracteres (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_pessoa_ex = 'N' AND TRIM(p_cnpj) IS NULL AND TRIM(p_cpf) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CNPJ/CPF não foi informado (' || p_apelido || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_pessoa_jur = 'S' AND TRIM(p_cnpj) IS NOT NULL THEN
   IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CNPJ inválido (' || p_cnpj || ').';
    RAISE v_exception;
   ELSE
    v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
   END IF;
  END IF;
  --
  IF p_flag_pessoa_jur = 'N' AND TRIM(p_cpf) IS NOT NULL THEN
   IF cpf_pkg.validar(p_cpf, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CPF inválido (' || p_cpf || ').';
    RAISE v_exception;
   ELSE
    v_cpf := cpf_pkg.converter(p_cpf, p_empresa_id);
   END IF;
  END IF;
  --
  IF v_cnpj IS NULL AND v_cpf IS NULL THEN
   v_flag_sem_docum := 'S';
  ELSE
   v_flag_sem_docum := 'N';
  END IF;
  --
  IF length(p_rg) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O RG não pode ter mais que 20 caracteres (' || p_rg || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_rg_org_exp) > 6 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O órgão expedidor do RG não pode ter mais que 6 caracteres (' || p_rg_org_exp || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_apolo_validar(p_rg_data_exp) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de expedição do RG inválida (' || p_rg_data_exp || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_rg_uf) IS NOT NULL THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_rg_uf)) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado do RG inválida (' || p_rg_uf || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF data_apolo_validar(p_data_nasc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de nascimento inválida (' || p_data_nasc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_inscr_estadual) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A inscrição estadual não pode ter mais que 20 caracteres (' || p_inscr_estadual || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_inscr_municipal) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A inscrição municipal não pode ter mais que 20 caracteres (' || p_inscr_municipal || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_inscr_inss) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A inscrição no INSS não pode ter mais que 20 caracteres (' || p_inscr_inss || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_endereco) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O endereço não pode ter mais que 100 caracteres (' || p_endereco || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_ender) = 0 OR to_number(p_num_ender) > 999999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do endereço inválido (' || p_num_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_compl_ender) > 30 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 30 caracteres (' || p_compl_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_zona) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A zona do endereço não pode ter mais que 60 caracteres (' || p_zona || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_bairro) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O bairro não pode ter mais que 60 caracteres (' || p_bairro || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_pais) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O país não pode ter mais que 100 caracteres (' || p_pais || ').';
   RAISE v_exception;
  END IF;
  --
  v_pais := TRIM(p_pais);
  --
  IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL') THEN
   v_pais := 'BRASIL';
  END IF;
  --
  IF p_flag_pessoa_ex = 'S' AND v_pais IS NULL THEN
   v_pais := 'ESTRANGEIRO';
  END IF;
  --
  IF p_flag_pessoa_ex = 'S' AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Foi indicada pessoa no estrangeiro com endereço no Brasil.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cep) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   IF cep_pkg.validar(p_cep) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido (' || p_cep || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_cidade) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O município não pode ter mais que 60 caracteres (' || p_cidade || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_uf) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM dicionario
    WHERE tipo = 'estado'
      AND codigo = upper(rtrim(p_uf));
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida (' || p_uf || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_ddd_telefone) > 3 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O DDD do telefone não pode ter mais que 3 caracteres (' || p_ddd_telefone || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_telefone) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do telefone não pode ter mais que 80 caracteres (' || p_num_telefone || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_ramal) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ramal não pode ter mais que 80 caracteres (' || p_num_ramal || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_ddd_fax) > 3 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O DDD do fax não pode ter mais que 3 caracteres (' || p_ddd_fax || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_fax) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do fax não pode ter mais que 80 caracteres (' || p_num_fax || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_ddd_celular) > 3 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O DDD do celular não pode ter mais que 3 caracteres (' || p_ddd_celular || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_celular) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do celular não pode ter mais que 80 caracteres (' || p_num_celular || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_email) > 50 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O email não pode ter mais que 50 caracteres (' || p_email || ').';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_email) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido (' || p_email || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_website) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O website não pode ter mais que 100 caracteres (' || p_website || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_banco) IS NOT NULL THEN
   SELECT MAX(fi_banco_id)
     INTO v_fi_banco_id
     FROM fi_banco
    WHERE codigo = p_cod_banco;
   --
   IF v_fi_banco_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código do banco inválido (' || p_cod_banco || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_num_agencia) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da agência bancária não pode ter mais que 10 caracteres (' ||
                 p_num_agencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_conta) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da conta bancária não pode ter mais que 20 caracteres (' || p_num_conta || ').';
   RAISE v_exception;
  END IF;
  --
  /*
    IF (v_fi_banco_id IS NOT NULL AND (p_num_agencia IS NULL OR p_num_conta IS NULL)) OR
       (v_fi_banco_id IS NULL AND (p_num_agencia IS NOT NULL OR p_num_conta IS NOT NULL)) THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Dados bancários incompletos.';
       RAISE v_exception;
    END IF;
  */
  --
  IF rtrim(p_tipo_conta) IS NOT NULL AND p_tipo_conta NOT IN ('C', 'P') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta bancária inválido (' || p_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome_titular) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O titular da conta bancária não pode ter mais que 60 caracteres (' ||
                 p_nome_titular || ').';
   RAISE v_exception;
  END IF;
  --
  v_cnpj_cpf_titular := NULL;
  --
  IF TRIM(p_cnpj_cpf_titular) IS NOT NULL THEN
   IF cpf_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0 THEN
    IF cnpj_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'CNPJ/CPF do titular da conta inválido (' || p_cnpj_cpf_titular || ').';
     RAISE v_exception;
    ELSE
     v_cnpj_cpf_titular := cnpj_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
    END IF;
   ELSE
    v_cnpj_cpf_titular := cpf_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
   END IF;
  END IF;
  --
  v_flag_pessoa_impostos_zerar := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                 'FLAG_PESSOA_IMPOSTOS_ZERAR');
  IF v_flag_pessoa_impostos_zerar = 'S' THEN
   v_perc_imposto := 0;
  ELSE
   v_perc_imposto := NULL;
  END IF;
  --
  -- tenta localizar a pessoa pelo codigo externo
  SELECT MAX(pe.pessoa_id)
    INTO v_pessoa_id
    FROM pessoa          pe,
         pessoa_sist_ext ps
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.cod_ext_pessoa = p_cod_ext_pessoa
     AND ps.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_pessoa_id IS NULL THEN
   -- tenta localizar a pessoa pelo CNPJ/CPF
   IF v_cnpj IS NOT NULL THEN
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE cnpj = v_cnpj
       AND empresa_id = p_empresa_id;
   END IF;
   --
   IF v_cpf IS NOT NULL THEN
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE cpf = v_cpf
       AND empresa_id = p_empresa_id;
   END IF;
  END IF;
  --
  -- recupera a empresa responsavel padrao
  SELECT MIN(pessoa_id)
    INTO v_emp_resp_pdr_id
    FROM pessoa
   WHERE flag_emp_resp = 'S'
     AND empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF p_operacao IN ('INCLUIR', 'ALTERAR') THEN
   IF v_pessoa_id IS NOT NULL THEN
    -- pessoa ja existe no JobOne. Atualiza o registro
    v_cod_evento := 'ALTERAR';
    --
    UPDATE pessoa
       SET apelido         = TRIM(p_apelido),
           nome            = TRIM(p_nome),
           cnpj            = v_cnpj,
           cpf             = v_cpf,
           flag_sem_docum  = v_flag_sem_docum,
           rg              = p_rg,
           rg_org_exp      = p_rg_org_exp,
           rg_data_exp     = data_apolo_converter(p_rg_data_exp),
           rg_uf           = upper(TRIM(p_rg_uf)),
           inscr_estadual  = TRIM(p_inscr_estadual),
           inscr_municipal = TRIM(p_inscr_municipal),
           inscr_inss      = TRIM(p_inscr_inss),
           flag_pessoa_jur = p_flag_pessoa_jur,
           endereco        = p_endereco,
           num_ender       = p_num_ender,
           compl_ender     = p_compl_ender,
           bairro          = TRIM(p_bairro),
           zona            = TRIM(p_zona),
           cep             = cep_pkg.converter(rtrim(p_cep)),
           cidade          = TRIM(p_cidade),
           uf              = TRIM(upper(p_uf)),
           pais            = v_pais,
           email           = TRIM(p_email),
           website         = TRIM(p_website),
           ddd_telefone    = p_ddd_telefone,
           num_telefone    = p_num_telefone,
           num_ramal       = p_num_ramal,
           ddd_celular     = p_ddd_celular,
           num_celular     = p_num_celular,
           emp_resp_pdr_id = v_emp_resp_pdr_id
     WHERE pessoa_id = v_pessoa_id;
    --
    -- so atualiza dados bancarios se nao estiverem
    -- preenchidos no JobOne
    UPDATE pessoa
       SET fi_banco_id      = v_fi_banco_id,
           num_agencia      = p_num_agencia,
           num_conta        = p_num_conta,
           tipo_conta       = p_tipo_conta,
           nome_titular     = TRIM(p_nome_titular),
           cnpj_cpf_titular = v_cnpj_cpf_titular
     WHERE pessoa_id = v_pessoa_id
       AND fi_banco_id IS NULL
       AND TRIM(num_conta) IS NULL;
   ELSE
    -- pessoa nao existe no JobOne. Cria o registro
    v_cod_evento := 'INCLUIR';
    LOCK TABLE pessoa IN EXCLUSIVE MODE;
    --
    IF v_cpf IS NOT NULL THEN
     -- testa de novo por causa de processamentos paralelos
     SELECT COUNT(*)
       INTO v_qt
       FROM pessoa
      WHERE cpf = v_cpf
        AND empresa_id = p_empresa_id;
     --
     IF v_qt > 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'CPF em processamento. Tente novamente.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF v_cnpj IS NOT NULL THEN
     -- testa de novo por causa de processamentos paralelos
     SELECT COUNT(*)
       INTO v_qt
       FROM pessoa
      WHERE cnpj = v_cnpj
        AND empresa_id = p_empresa_id;
     --
     IF v_qt > 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'CNPJ em processamento. Tente novamente.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    SELECT seq_pessoa.nextval
      INTO v_pessoa_id
      FROM dual;
    --
    INSERT INTO pessoa
     (empresa_id,
      apelido,
      pessoa_id,
      nome,
      cnpj,
      cpf,
      flag_sem_docum,
      rg,
      rg_org_exp,
      rg_data_exp,
      rg_uf,
      inscr_estadual,
      inscr_municipal,
      inscr_inss,
      flag_pessoa_jur,
      endereco,
      num_ender,
      compl_ender,
      bairro,
      zona,
      cep,
      cidade,
      uf,
      pais,
      email,
      website,
      ddd_telefone,
      num_telefone,
      num_ramal,
      ddd_celular,
      num_celular,
      fi_banco_id,
      num_agencia,
      num_conta,
      tipo_conta,
      nome_titular,
      cnpj_cpf_titular,
      flag_emp_fatur,
      flag_emp_resp,
      flag_ativo,
      flag_pago_cliente,
      emp_resp_pdr_id)
    VALUES
     (p_empresa_id,
      TRIM(p_apelido),
      v_pessoa_id,
      TRIM(p_nome),
      v_cnpj,
      v_cpf,
      v_flag_sem_docum,
      TRIM(p_rg),
      TRIM(p_rg_org_exp),
      data_apolo_converter(p_rg_data_exp),
      upper(TRIM(p_rg_uf)),
      TRIM(p_inscr_estadual),
      TRIM(p_inscr_municipal),
      TRIM(p_inscr_inss),
      p_flag_pessoa_jur,
      TRIM(p_endereco),
      p_num_ender,
      TRIM(p_compl_ender),
      TRIM(p_bairro),
      TRIM(p_zona),
      cep_pkg.converter(rtrim(p_cep)),
      TRIM(p_cidade),
      TRIM(upper(p_uf)),
      v_pais,
      TRIM(p_email),
      TRIM(p_website),
      p_ddd_telefone,
      p_num_telefone,
      p_num_ramal,
      p_ddd_celular,
      p_num_celular,
      v_fi_banco_id,
      p_num_agencia,
      p_num_conta,
      p_tipo_conta,
      TRIM(p_nome_titular),
      v_cnpj_cpf_titular,
      'N',
      'N',
      'S',
      'N',
      v_emp_resp_pdr_id);
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
            v_perc_imposto,
            'N',
            NULL
       FROM fi_tipo_imposto
      WHERE flag_incide_ent = 'S';
   END IF;
   --
   -- processamento final apos inclusao / alteracao
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_qt = 0 THEN
    -- cria a pessoa com o tipo especificado
    INSERT INTO tipific_pessoa
     (pessoa_id,
      tipo_pessoa_id)
    VALUES
     (v_pessoa_id,
      v_tipo_pessoa_id);
   END IF;
   --
   IF p_flag_pessoa_ex = 'S' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_est_id;
    --
    IF v_qt = 0 THEN
     -- cria a pessoa com o tipo ESTRANGEIRO
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa_est_id);
    END IF;
   END IF;
   --
   --
   DELETE FROM pessoa_sist_ext
    WHERE sistema_externo_id = p_sistema_externo_id
      AND pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   INSERT INTO pessoa_sist_ext
    (sistema_externo_id,
     pessoa_id,
     tipo_pessoa_id,
     cod_ext_pessoa)
   VALUES
    (p_sistema_externo_id,
     v_pessoa_id,
     v_tipo_pessoa_id,
     p_cod_ext_pessoa);
   --
   IF p_flag_pessoa_ex = 'S' THEN
    DELETE FROM pessoa_sist_ext
     WHERE sistema_externo_id = p_sistema_externo_id
       AND pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_est_id;
    --
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      v_pessoa_id,
      v_tipo_pessoa_est_id,
      p_cod_ext_pessoa);
   END IF;
  END IF; -- fim do IF p_operacao IN ('INCLUIR','ALTERAR')
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF p_operacao = 'EXCLUIR' THEN
   IF v_pessoa_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Pessoa a ser excluída não encontrada (CNPJ/CPF: ' || p_apelido || ').';
    RAISE v_exception;
   END IF;
   --
   -- desassocia a pessoa desse tipo
   DELETE FROM pessoa_sist_ext
    WHERE sistema_externo_id = p_sistema_externo_id
      AND pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   DELETE FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF p_flag_pessoa_ex = 'S' THEN
    DELETE FROM pessoa_sist_ext
     WHERE sistema_externo_id = p_sistema_externo_id
       AND pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_est_id;
    --
    DELETE FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_est_id;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id;
   --
   IF v_qt = 0 THEN
    v_cod_evento := 'EXCLUIR';
    -- pessoa nao tem mais nenhum tipo. tenta excluir.
    SELECT COUNT(*)
      INTO v_qt
      FROM job
     WHERE cliente_id = v_pessoa_id
       AND rownum = 1;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse cliente.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_cliente
     WHERE pessoa_id = v_pessoa_id
       AND rownum = 1;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem produtos associados a esse cliente.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_hora
     WHERE cliente_id = v_pessoa_id
       AND rownum = 1;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem apontamentos de horas para esse cliente.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM nota_fiscal
     WHERE cliente_id = v_pessoa_id
       AND rownum = 1;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem notas fiscais associadas a esse cliente.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM nota_fiscal
     WHERE emp_emissora_id = v_pessoa_id
       AND rownum = 1;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem notas fiscais associadas a esse fornecedor.';
     RAISE v_exception;
    END IF;
    --
    DELETE FROM fi_tipo_imposto_pessoa
     WHERE pessoa_id = v_pessoa_id;
    DELETE FROM natureza_oper_fatur
     WHERE pessoa_id = v_pessoa_id;
    DELETE FROM pessoa
     WHERE pessoa_id = v_pessoa_id;
   ELSE
    -- como a pessoa ainda esta tipificada, mantem o registro
    v_cod_evento := 'ALTERAR';
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := 'Integração Apolo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  p_pessoa_id := v_pessoa_id;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END pessoa_atualizar;
 --
 --
 --
 PROCEDURE tipo_produto_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 31/10/2013
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do APOLO referentes a
  --  integração de TIPO_PRODUTO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2014  Novos tipos de produto sao inseridos como INATIVO.
  -- Silvia            27/10/2014  Novos tipos de produto sao inseridos como ATIVO.
  -- Silvia            22/11/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_cod_agencia IN VARCHAR2,
  p_cod_acao    IN VARCHAR2,
  p_xml_in      IN CLOB,
  p_xml_out     OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_erro_cod            VARCHAR2(20);
  v_erro_msg            VARCHAR2(200);
  v_xml_in              xmltype;
  v_xml_retorno         CLOB;
  v_xml_log_id          xml_log.xml_log_id%TYPE;
  v_sistema_externo_id  sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id   usuario.usuario_id%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_tipo_produto_id     tipo_produto.tipo_produto_id%TYPE;
  v_flag_sistema        tipo_produto.flag_sistema%TYPE;
  v_categoria_id        VARCHAR2(40);
  v_caminho_campos      VARCHAR2(100);
  v_operacao            VARCHAR2(10);
  v_sistema             VARCHAR2(40);
  v_processo            VARCHAR2(40);
  v_processo_xml        VARCHAR2(40);
  v_cod_ext_produto     VARCHAR2(100);
  v_cod_ext_produto_aux VARCHAR2(100);
  v_nome                VARCHAR2(500);
  v_cod_evento          VARCHAR2(40);
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  v_processo := 'TIPO_PRODUTO';
  --
  IF TRIM(p_cod_acao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_xml_in IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'XML não fornecido.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'APOLO', 'JOBONE', 'TIPO_PRODUTO', p_cod_acao, NULL, p_xml_in);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'APOLO_ESFERABR';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (APOLO_ESFERA).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa
   WHERE codigo = p_cod_agencia;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da agência não encontrado (' || p_cod_agencia || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- extracao do cabecalho
  ------------------------------------------------------------
  --
  SELECT xmltype(TRIM(p_xml_in))
    INTO v_xml_in
    FROM dual;
  --
  SELECT TRIM(extractvalue(v_xml_in, '/mensagem/cabecalho/sistema')),
         TRIM(extractvalue(v_xml_in, '/mensagem/cabecalho/processo'))
    INTO v_sistema,
         v_processo_xml
    FROM dual;
  --
  v_sistema      := upper(v_sistema);
  v_processo_xml := upper(v_processo_xml);
  --
  IF v_sistema IS NULL OR v_sistema <> 'JOBONE' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do sistema inválido (' || v_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_processo_xml IS NULL OR v_processo_xml <> v_processo THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do processo inválido (' || v_processo_xml || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- extracao dos detalhes do tipo de produto
  ------------------------------------------------------------
  v_caminho_campos := '/mensagem/conteudo/';
  --
  SELECT TRIM(extractvalue(v_xml_in, v_caminho_campos || 'cod_externo')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'nome')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'categoria'))
    INTO v_cod_ext_produto,
         v_nome,
         v_categoria_id
    FROM dual;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  IF rtrim(v_cod_ext_produto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código Apolo do tipo de produto é obrigatório (' || v_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_cod_ext_produto) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código Apolo do tipo de produto não pode ter mais que 20 caracteres (' ||
                 v_cod_ext_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(v_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do tipo de produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_nome) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do tipo de produto não pode ter mais que 60 caracteres (' || v_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF instr(v_nome, ',') > 0 OR instr(v_nome, ';') > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do tipo de produto não pode conter vírgula ou ponto-e-vírgula (' || v_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_categoria_id IS NULL THEN
   v_categoria_id := 'ND';
  END IF;
  --
  IF util_pkg.desc_retornar('categoria_tipo_prod', v_categoria_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Categoria do produto inválida (' || v_categoria_id || ').';
   RAISE v_exception;
  END IF;
  --
  -- tenta localizar o produto pelo codigo externo
  SELECT MAX(tipo_produto_id)
    INTO v_tipo_produto_id
    FROM tipo_produto
   WHERE empresa_id = v_empresa_id
     AND cod_ext_produto = v_cod_ext_produto;
  --
  IF v_tipo_produto_id IS NULL THEN
   -- tenta localizar pelo nome
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_id
     FROM tipo_produto
    WHERE empresa_id = v_empresa_id
      AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome));
   --
   IF v_tipo_produto_id IS NOT NULL THEN
    -- verifica se o produto ja tem codigo Apolo
    SELECT cod_ext_produto
      INTO v_cod_ext_produto_aux
      FROM tipo_produto
     WHERE tipo_produto_id = v_tipo_produto_id;
    --
    IF v_cod_ext_produto_aux <> v_cod_ext_produto THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Produto recebido com código ' || v_cod_ext_produto ||
                   ' já se encontra cadastrado com outro código (' || v_cod_ext_produto_aux || ').';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF v_operacao IN ('INCLUIR', 'ALTERAR') THEN
   IF v_tipo_produto_id IS NOT NULL THEN
    -- produto ja existe no JobOne. Atualiza o registro
    v_cod_evento := 'ALTERAR';
    --
    SELECT flag_sistema
      INTO v_flag_sistema
      FROM tipo_produto
     WHERE tipo_produto_id = v_tipo_produto_id;
    --
    IF v_flag_sistema = 'S' THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser alterado (' || v_nome || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_produto
     WHERE empresa_id = v_empresa_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome))
       AND tipo_produto_id <> v_tipo_produto_id;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe outro tipo de produto com o mesmo nome (' || v_nome || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE tipo_produto
       SET nome            = TRIM(v_nome),
           cod_ext_produto = v_cod_ext_produto,
           categoria_id    = v_categoria_id
     WHERE tipo_produto_id = v_tipo_produto_id;
   ELSE
    -- produto nao existe no JobOne. Cria o registro
    v_cod_evento := 'INCLUIR';
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_produto
     WHERE empresa_id = v_empresa_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome));
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe outro tipo de produto com o mesmo nome (' || v_nome || ').';
     RAISE v_exception;
    END IF;
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
      flag_sistema,
      categoria_id)
    VALUES
     (v_empresa_id,
      v_tipo_produto_id,
      TRIM(v_nome),
      v_cod_ext_produto,
      'S',
      'N',
      v_categoria_id);
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(v_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF v_operacao = 'EXCLUIR' THEN
   v_cod_evento := 'EXCLUIR';
   --
   IF v_tipo_produto_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável a ser excluído não encontrado (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de produto está sendo referenciado por algum item (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de produto está sendo referenciado por Workflow ou Task (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_sistema
     INTO v_flag_sistema
     FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_flag_sistema = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser excluído (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   --
   DELETE FROM metadado
    WHERE objeto_id = v_tipo_produto_id
      AND tipo_objeto = 'TIPO_PRODUTO'
      AND empresa_id = v_empresa_id;
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
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Integração Apolo';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao do xml de retorno
  ------------------------------------------------------------
  xml_retorno_gerar(v_sistema_externo_id,
                    v_empresa_id,
                    '00000',
                    v_processo,
                    v_tipo_produto_id,
                    NULL,
                    v_xml_retorno,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao do log
  ------------------------------------------------------------
  log_concluir(v_xml_log_id, v_tipo_produto_id, v_xml_retorno);
  --
  p_xml_out := v_xml_retorno;
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: ' || p_erro_msg;
   --
   xml_retorno_gerar(v_sistema_externo_id,
                     v_empresa_id,
                     p_erro_cod,
                     v_processo,
                     v_tipo_produto_id,
                     p_erro_msg,
                     v_xml_retorno,
                     v_erro_cod,
                     v_erro_msg);
   --
   log_concluir(v_xml_log_id, v_tipo_produto_id, v_xml_retorno);
   --
   p_xml_out := v_xml_retorno;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na geração do arquivo de retorno. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
   ROLLBACK;
 END tipo_produto_processar;
 --
 --
 --
 PROCEDURE nf_saida_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/08/2013
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do APOLO referentes a
  --  integração nota fiscal de saida.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_cod_agencia IN VARCHAR2,
  p_cod_acao    IN VARCHAR2,
  p_xml_in      IN CLOB,
  p_xml_out     OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_erro_cod           VARCHAR2(20);
  v_erro_msg           VARCHAR2(200);
  v_xml_in             xmltype;
  v_xml_retorno        CLOB;
  v_xml_log_id         xml_log.xml_log_id%TYPE;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_nome_empresa       empresa.nome%TYPE;
  v_caminho_campos     VARCHAR2(100);
  v_operacao           VARCHAR2(10);
  v_sistema            VARCHAR2(40);
  v_processo           VARCHAR2(40);
  v_processo_xml       VARCHAR2(40);
  v_nota_fiscal_id     nota_fiscal.nota_fiscal_id%TYPE;
  v_emp_emissora_id    nota_fiscal.emp_emissora_id%TYPE;
  v_num_doc            nota_fiscal.num_doc%TYPE;
  v_num_serie          nota_fiscal.serie%TYPE;
  v_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_tipo_doc_nf_id     nota_fiscal.tipo_doc_nf_id%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_data_entrada       nota_fiscal.data_entrada%TYPE;
  v_valor_bruto        nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_aux    nota_fiscal.valor_bruto%TYPE;
  v_emp_cnpj           pessoa.cnpj%TYPE;
  v_cod_ext_cliente    pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id             job.job_id%TYPE;
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_item_id            item.item_id%TYPE;
  v_tipo_doc_nf        tipo_doc_nf.codigo%TYPE;
  v_valor_fatura       NUMBER;
  v_item_char          VARCHAR2(20);
  v_data_emissao_char  VARCHAR2(20);
  v_tipo_doc           VARCHAR2(20);
  v_uf_servico         VARCHAR2(20);
  v_valor_bruto_char   VARCHAR2(20);
  v_faturamento_char   VARCHAR2(20);
  v_doc_identif        VARCHAR2(100);
  v_nfeletr            VARCHAR2(100);
  --
  CURSOR c_it IS
   SELECT extractvalue(VALUE(item), '/item/D2_XPRODO') item_id,
          extractvalue(VALUE(item), '/item/D2_XPIPC') num_carta_acordo,
          extractvalue(VALUE(item), '/item/D2_TOTAL') valor_item
     FROM TABLE(xmlsequence(extract(v_xml_in, v_caminho_campos || v_processo || '_SD2/items/item'))) item;
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  v_processo := 'NOTA_FISCAL_SAIDA';
  --
  IF TRIM(p_cod_acao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_xml_in IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'XML não fornecido.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'APOLO', 'JOBONE', 'NF_SAIDA', p_cod_acao, NULL, p_xml_in);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'APOLO_ESFERABR';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (APOLO_ESFERABR).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- extracao do cabecalho
  ------------------------------------------------------------
  SELECT xmltype(TRIM(p_xml_in))
    INTO v_xml_in
    FROM dual;
  --
  SELECT TRIM(extractvalue(v_xml_in, '/TOTVSIntegrator/GlobalProduct')),
         TRIM(extractvalue(v_xml_in, '/TOTVSIntegrator/GlobalDocumentFunctionCode'))
    INTO v_sistema,
         v_processo_xml
    FROM dual;
  --
  SELECT MAX(em.empresa_id),
         MAX(em.nome),
         MAX(pe.pessoa_id)
    INTO v_empresa_id,
         v_nome_empresa,
         v_emp_emissora_id
    FROM empr_fatur_sist_ext es,
         pessoa              pe,
         empresa             em
   WHERE es.sistema_externo_id = v_sistema_externo_id
     AND es.cod_ext_fatur = 'xxxx'
     AND es.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = em.empresa_id;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do grupo/empresa não encontrado (' || 'xxxx' || ').';
   RAISE v_exception;
  END IF;
  --
  v_sistema      := upper(v_sistema);
  v_processo_xml := upper(v_processo_xml);
  --
  IF v_sistema IS NULL OR v_sistema <> 'JOBONE' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do sistema inválido (' || v_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_processo_xml IS NULL OR v_processo_xml <> v_processo THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do processo inválido (' || v_processo_xml || ').';
   RAISE v_exception;
  END IF;
  --
  v_caminho_campos := '/TOTVSIntegrator/Message/Layouts/Content/' || v_processo || '/' ||
                      v_processo || '_SF2/';
  --
  ------------------------------------------------------------
  -- extracao dos detalhes
  ------------------------------------------------------------
  SELECT TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_DOC/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_SERIE/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_XIDCLIE/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_EMISSAO/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_EST/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_XNUMPV/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_VALBRUT/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_ESPECIE/value')),
         TRIM(extractvalue(v_xml_in, v_caminho_campos || 'F2_NFELETR/value')),
         TRIM(extractvalue(v_xml_in,
                           v_caminho_campos || v_processo || '_SD2/items/item[1]/D2_XPRODO'))
    INTO v_num_doc,
         v_num_serie,
         v_cod_ext_cliente,
         v_data_emissao_char,
         v_uf_servico,
         v_faturamento_char,
         v_valor_bruto_char,
         v_tipo_doc,
         v_nfeletr,
         v_item_char
    FROM dual;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF v_num_doc IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da nota fiscal de saída é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(v_num_doc) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do documento de entrada não pode ter mais que 10 caracteres (' ||
                 v_num_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_num_serie) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A série do documento de entrada não pode ter mais que 10 caracteres (' ||
                 v_num_serie || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_doc IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo da nota fiscal de saída é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_doc_nf_id),
         MAX(codigo)
    INTO v_tipo_doc_nf_id,
         v_tipo_doc_nf
    FROM tipo_doc_nf
   WHERE codigo = decode(v_tipo_doc,
                         'NF',
                         'NF',
                         'NFE',
                         'NF',
                         'SPED',
                         'NF',
                         'RPS',
                         'REC',
                         'RPA',
                         'REC',
                         'LOC',
                         'NFL',
                         'ALU',
                         'NFL',
                         'FAT',
                         'NFF',
                         'NFS',
                         'NFS',
                         'NFP',
                         'NFP',
                         'NF');
  --
  IF v_tipo_doc_nf_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo da nota fiscal de saída inválido (' || v_tipo_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_data_emissao_char IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de emissão da nota fiscal de saída é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF data_apolo_validar(v_data_emissao_char) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão da nota fiscal de saída inválida (' || v_data_emissao_char || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_emissao := data_apolo_converter(v_data_emissao_char);
  v_data_entrada := SYSDATE;
  --
  SELECT MAX(pe.pessoa_id)
    INTO v_cliente_id
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp,
         pessoa          pe
   WHERE ps.sistema_externo_id = v_sistema_externo_id
     AND ps.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = v_empresa_id
     AND ps.cod_ext_pessoa = v_cod_ext_cliente
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cliente_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do cliente não encontrado na empresa ' || v_nome_empresa || ' (' ||
                 v_cod_ext_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(cnpj, cpf)
    INTO v_emp_cnpj
    FROM pessoa
   WHERE pessoa_id = v_emp_emissora_id;
  --
  v_doc_identif := v_tipo_doc_nf || ': ' || v_emp_cnpj || '/' || v_num_doc;
  IF v_num_serie IS NOT NULL THEN
   v_doc_identif := v_doc_identif || '-' || v_num_serie;
  END IF;
  --
  IF v_valor_bruto_char IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal de saída não informado (' || v_doc_identif || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_apolo_validar(v_valor_bruto_char) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal de saída inválido (' || v_doc_identif ||
                 ' Valor bruto: ' || v_valor_bruto_char || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_bruto := numero_apolo_converter(v_valor_bruto_char);
  --
  IF inteiro_validar(v_faturamento_char) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem de faturamento da nota fiscal de saída inválido (' || v_doc_identif ||
                 ' Ordem: ' || v_faturamento_char || ').';
   RAISE v_exception;
  END IF;
  --
  v_faturamento_id := nvl(to_number(v_faturamento_char), 0);
  --
  ------------------------------------------------------------
  -- processamento da exclusao
  ------------------------------------------------------------
  IF v_operacao = 'EXCLUIR' THEN
   SELECT MAX(nota_fiscal_id)
     INTO v_nota_fiscal_id
     FROM nota_fiscal
    WHERE emp_emissora_id = v_emp_emissora_id
      AND tipo_doc_nf_id = v_tipo_doc_nf_id
      AND num_doc = v_num_doc
      AND nvl(serie, 'ZZZ') = nvl(v_num_serie, 'ZZZ')
      AND tipo_ent_sai = 'S';
   --
   IF v_nota_fiscal_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nota fiscal de saída não encontrada (' || v_doc_identif || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT valor_bruto
     INTO v_valor_bruto_aux
     FROM nota_fiscal
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   IF v_valor_bruto <> v_valor_bruto_aux THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor bruto da nota fiscal de saída não confere (' || ' Valor bruto JobOne: ' ||
                  moeda_mostrar(v_valor_bruto_aux, 'S') || ' Valor bruto Apolo:' ||
                  moeda_mostrar(v_valor_bruto, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE faturamento
      SET nota_fiscal_sai_id = NULL
    WHERE nota_fiscal_sai_id = v_nota_fiscal_id;
   --
   DELETE FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   DELETE FROM imposto_nota
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   DELETE FROM nota_fiscal
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- processamento da inclusao
  ------------------------------------------------------------
  IF v_operacao = 'INCLUIR' THEN
   SELECT MAX(nota_fiscal_id)
     INTO v_nota_fiscal_id
     FROM nota_fiscal
    WHERE emp_emissora_id = v_emp_emissora_id
      AND tipo_doc_nf_id = v_tipo_doc_nf_id
      AND num_doc = v_num_doc
      AND nvl(serie, 'ZZZ') = nvl(v_num_serie, 'ZZZ')
      AND tipo_ent_sai = 'S';
   --
   IF v_nota_fiscal_id IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nota fiscal de saída já cadastrada (' || v_doc_identif || ').';
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------
   -- verificacao do primeiro item enviado
   ------------------------------------------------------
   IF inteiro_validar(v_item_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item da nota fiscal de saída inválido (' || v_doc_identif || ' Item: ' ||
                  v_item_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_item_id := nvl(to_number(v_item_char), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item it,
          job  jo
    WHERE it.item_id = v_item_id
      AND it.job_id = jo.job_id
      AND jo.empresa_id = v_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item da nota fiscal de saída não encontrado (' || v_doc_identif || ' Item: ' ||
                  v_item_char || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT job_id
     INTO v_job_id
     FROM item
    WHERE item_id = v_item_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento
    WHERE faturamento_id = v_faturamento_id
      AND job_id = v_job_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Ordem de faturamento da nota fiscal de saída não encontrado (' || v_doc_identif ||
                  ' Ordem: ' || v_faturamento_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_fatura := faturamento_pkg.valor_fatura_retornar(v_faturamento_id);
   --
   IF nvl(v_valor_bruto, 0) <> v_valor_fatura THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor bruto da nota fiscal de saída (' || moeda_mostrar(v_valor_bruto, 'S') ||
                  ') não bate com o valor da ordem de faturamento (' ||
                  moeda_mostrar(v_valor_fatura, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------
   -- inclusao da nota fiscal
   ------------------------------------------------------
   SELECT seq_nota_fiscal.nextval
     INTO v_nota_fiscal_id
     FROM dual;
   --
   INSERT INTO nota_fiscal
    (nota_fiscal_id,
     job_id,
     cliente_id,
     emp_emissora_id,
     tipo_ent_sai,
     tipo_doc_nf_id,
     num_doc,
     serie,
     data_entrada,
     data_emissao,
     data_pri_vencim,
     valor_bruto,
     valor_mao_obra,
     uf_servico,
     status,
     chave_acesso)
   VALUES
    (v_nota_fiscal_id,
     v_job_id,
     v_cliente_id,
     v_emp_emissora_id,
     'S',
     v_tipo_doc_nf_id,
     TRIM(v_num_doc),
     TRIM(v_num_serie),
     v_data_entrada,
     v_data_emissao,
     NULL,
     v_valor_bruto,
     0,
     TRIM(v_uf_servico),
     'CONC',
     v_nfeletr);
   --
   ------------------------------------------------------
   -- tratamento dos itens (nao utilizado)
   ------------------------------------------------------
   v_valor_bruto_aux := 0;
   --
   FOR r_it IN c_it
   LOOP
    IF r_it.valor_item IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor do item é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF numero_apolo_validar(r_it.valor_item) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor do item inválido (' || r_it.valor_item || ').';
     RAISE v_exception;
    END IF;
    --
    v_valor_bruto_aux := v_valor_bruto_aux + numero_apolo_converter(r_it.valor_item);
   END LOOP;
   --
   --
   UPDATE nota_fiscal
      SET cod_ext_nf = 'J' || to_char(v_nota_fiscal_id)
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   UPDATE faturamento
      SET nota_fiscal_sai_id = v_nota_fiscal_id
    WHERE faturamento_id = v_faturamento_id;
   --
  END IF; -- fim do IF v_operacao = 'INCLUIR'
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc_nf || ': ' ||
                      TRIM(v_num_doc) || ' ' || TRIM(v_num_serie);
  v_compl_histor   := 'Integração Apolo';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'NOTA_FISCAL',
                   v_operacao,
                   v_identif_objeto,
                   v_nota_fiscal_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao do xml de retorno
  ------------------------------------------------------------
  xml_retorno_gerar(v_sistema_externo_id,
                    v_empresa_id,
                    '00000',
                    v_processo,
                    v_nota_fiscal_id,
                    NULL,
                    v_xml_retorno,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao do log
  ------------------------------------------------------------
  log_concluir(v_xml_log_id, v_nota_fiscal_id, v_xml_retorno);
  --
  p_xml_out := v_xml_retorno;
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: ' || p_erro_msg;
   --
   xml_retorno_gerar(v_sistema_externo_id,
                     v_empresa_id,
                     p_erro_cod,
                     v_processo,
                     v_nota_fiscal_id,
                     p_erro_msg,
                     v_xml_retorno,
                     v_erro_cod,
                     v_erro_msg);
   --
   log_concluir(v_xml_log_id, v_nota_fiscal_id, v_xml_retorno);
   --
   p_xml_out := v_xml_retorno;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na geração do arquivo de retorno. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
   ROLLBACK;
 END nf_saida_processar;
 --
 --
 --
 PROCEDURE carta_acordo_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/07/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de carta acordo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                       INTEGER;
  v_exception                EXCEPTION;
  v_saida                    EXCEPTION;
  v_xml_conteudo             xmltype;
  v_xml_mensagem             xmltype;
  v_xml_conteudo_itens       xmltype;
  v_xml_conteudo_itens_aux   xmltype;
  v_xml_conteudo_itens_aux1  xmltype;
  v_xml_conteudo_itens_aux2  xmltype;
  v_xml_conteudo_itens_aux22 xmltype;
  v_xml_conteudo_parc        xmltype;
  v_xml_conteudo_parc_aux    xmltype;
  v_xml_out                  CLOB;
  v_xml_in                   CLOB;
  v_num_carta_acordo         VARCHAR2(60);
  v_job_id                   carta_acordo.job_id%TYPE;
  v_cod_ext_carta            carta_acordo.cod_ext_carta%TYPE;
  v_data_emissao             carta_acordo.data_emissao%TYPE;
  v_data_criacao             carta_acordo.data_criacao%TYPE;
  v_cliente_id               carta_acordo.cliente_id%TYPE;
  v_fornecedor_id            carta_acordo.fornecedor_id%TYPE;
  v_emp_faturar_por_id       carta_acordo.emp_faturar_por_id%TYPE;
  v_desc_item                carta_acordo.desc_item%TYPE;
  v_valor_credito_usado      carta_acordo.valor_credito_usado%TYPE;
  v_valor_aprovado           carta_acordo.valor_aprovado%TYPE;
  v_tipo_fatur_bv            carta_acordo.tipo_fatur_bv%TYPE;
  v_tipo_produto_id          item_carta.tipo_produto_id%TYPE;
  v_custo_unitario           item_carta.custo_unitario%TYPE;
  v_data_entrega             DATE;
  v_cod_ext_condicao         condicao_pagto.cod_ext_condicao%TYPE;
  v_cod_ext_cliente          pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_fornecedor       pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_usuario          usuario.cod_ext_usuario%TYPE;
  v_usuario_aprov            usuario.cod_ext_usuario%TYPE;
  v_nome_produto             tipo_produto.nome%TYPE;
  v_cnpj_cpf                 VARCHAR2(50);
  v_qtd_freq_char            VARCHAR2(50);
  v_custo_unitario_char      VARCHAR2(100);
  v_valor_item_char          VARCHAR2(100);
  v_operacao                 VARCHAR2(500);
  v_num_seq_it               INTEGER;
  v_num_seq_job              INTEGER;
  v_perc_desconto            NUMBER;
  v_valor_rateio             NUMBER;
  v_valor_final              NUMBER;
  v_valor_acum               NUMBER;
  v_valor_ult_rateio         NUMBER;
  v_num_ult_seq_it           INTEGER;
  v_num_ult_seq_job          INTEGER;
  --
  -- cursor que totaliza valores por tipo de produto
  CURSOR c_itn1 IS
   SELECT nvl(ic.tipo_produto_id, it.tipo_produto_id) AS tipo_produto_id,
          TRIM(tp.cod_ext_produto) AS cod_ext_produto,
          tp.categoria_id,
          nvl(ic.custo_unitario, it.custo_unitario) AS custo_unitario,
          SUM(ic.quantidade * ic.frequencia) AS quantidade,
          SUM(ic.valor_aprovado) AS valor_aprovado
     FROM item_carta   ic,
          item         it,
          tipo_produto tp
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND nvl(ic.tipo_produto_id, it.tipo_produto_id) = tp.tipo_produto_id
      AND ic.item_id = it.item_id
    GROUP BY nvl(ic.tipo_produto_id, it.tipo_produto_id),
             tp.cod_ext_produto,
             tp.categoria_id,
             nvl(ic.custo_unitario, it.custo_unitario)
    ORDER BY 1;
  --
  -- cursor para rateio do tipo de produto por job
  CURSOR c_itn2 IS
   SELECT jo.job_id,
          jo.numero AS num_job,
          nvl(SUM(ic.valor_aprovado), 0) AS valor
     FROM item_carta ic,
          item       it,
          job        jo
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id
      AND it.job_id = jo.job_id
      AND nvl(ic.tipo_produto_id, it.tipo_produto_id) = v_tipo_produto_id
      AND nvl(ic.custo_unitario, it.custo_unitario) = v_custo_unitario
    GROUP BY jo.numero,
             jo.job_id
    ORDER BY 1;
  --
  CURSOR c_par IS
   SELECT num_parcela,
          data_parcela,
          valor_parcela,
          num_dias
     FROM parcela_carta
    WHERE carta_acordo_id = p_carta_acordo_id
    ORDER BY num_parcela;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  SELECT ca.job_id,
         cl.pessoa_id,
         fo.pessoa_id,
         ca.cod_ext_carta,
         ca.data_emissao,
         ca.data_criacao,
         ca.emp_faturar_por_id,
         ca.desc_item,
         cp.cod_ext_condicao,
         data_converter(TRIM(extractvalue(xmltype(ca.texto_xml), '/conteudo/entrega/data_produto'))),
         nvl(cl.cnpj, cl.cpf),
         us.cod_ext_usuario,
         nvl(ca.valor_credito_usado, 0),
         nvl(ca.valor_aprovado, 0),
         ca.tipo_fatur_bv
    INTO v_job_id,
         v_cliente_id,
         v_fornecedor_id,
         v_cod_ext_carta,
         v_data_emissao,
         v_data_criacao,
         v_emp_faturar_por_id,
         v_desc_item,
         v_cod_ext_condicao,
         v_data_entrega,
         v_cnpj_cpf,
         v_cod_ext_usuario,
         v_valor_credito_usado,
         v_valor_aprovado,
         v_tipo_fatur_bv
    FROM carta_acordo   ca,
         pessoa         cl,
         pessoa         fo,
         usuario        us,
         condicao_pagto cp
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.cliente_id = cl.pessoa_id
     AND ca.fornecedor_id = fo.pessoa_id
     AND ca.produtor_id = us.usuario_id(+)
     AND ca.condicao_pagto_id = cp.condicao_pagto_id(+);
  --
  v_num_carta_acordo := carta_acordo_pkg.numero_completo_formatar(p_carta_acordo_id, 'N');
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_cliente
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_fornecedor
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_fornecedor_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'FORNECEDOR';
  --
  IF v_valor_credito_usado = v_valor_aprovado OR v_tipo_fatur_bv = 'PER' THEN
   -- nao integra a carta acordo (saldo zero ou permuta)
   RAISE v_saida;
  END IF;
  --
  IF v_cod_ext_cliente IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O cliente dessa carta acordo não está integrado com o Apolo.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_fornecedor IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor dessa carta acordo não está integrado com o Apolo.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   IF v_cod_ext_usuario IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O produtor dessa carta acordo não está integrado com o Apolo.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_ext_condicao IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento dessa carta acordo não está integrada com o Apolo.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_perc_desconto := 0;
  v_valor_final   := v_valor_aprovado;
  --
  IF v_valor_credito_usado > 0 THEN
   v_perc_desconto := round(v_valor_credito_usado * 100 / v_valor_aprovado, 4);
   v_valor_final   := v_valor_aprovado - v_valor_credito_usado;
  END IF;
  --
  SELECT MAX(us.cod_ext_usuario)
    INTO v_usuario_aprov
    FROM historico   hi,
         evento      ev,
         tipo_objeto ob,
         tipo_acao   ac,
         usuario     us
   WHERE hi.evento_id = ev.evento_id
     AND hi.usuario_id = us.usuario_id
     AND ev.tipo_objeto_id = ob.tipo_objeto_id
     AND ev.tipo_acao_id = ac.tipo_acao_id
     AND ob.codigo = 'CARTA_ACORDO'
     AND ac.codigo = 'APROVAR'
     AND hi.objeto_id = p_carta_acordo_id;
  --
  IF v_usuario_aprov IS NULL THEN
   v_usuario_aprov := 'JOBONE';
  END IF;
  --
  ------------------------------------------------------------
  -- processamento da Carta Acordo
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IN ('I', 'A') THEN
   -- monta a secao "conteudo"
   SELECT xmlconcat(xmlelement("EmpCpfCgc", v_cnpj_cpf),
                    xmlelement("PedCompTipo", 'Total'),
                    xmlelement("PedCompData", data_apolo_mostrar(v_data_emissao)),
                    xmlelement("PedCompDataCad", data_apolo_mostrar(v_data_criacao)),
                    xmlelement("PedCompDataValidade", NULL),
                    xmlelement("PedCompDataEntrega", data_apolo_mostrar(v_data_entrega)),
                    xmlelement("EntCod", v_cod_ext_fornecedor),
                    xmlelement("UsuCod", 'JOBONE'),
                    xmlelement("PedCompAprov", 'Total'),
                    xmlelement("PedCompTexto", v_desc_item),
                    xmlelement("PedCompNumPedEntOrig", v_num_carta_acordo),
                    xmlelement("CompradCod", v_cod_ext_usuario),
                    xmlelement("IndEconSimb", 'R$'))
     INTO v_xml_conteudo
     FROM dual;
   --
   ------------------------------------------------------------
   -- monta a secao "itens"
   ------------------------------------------------------------
   v_num_seq_it := 0;
   v_valor_acum := 0;
   --
   FOR r_itn1 IN c_itn1
   LOOP
    IF r_itn1.cod_ext_produto IS NULL THEN
     SELECT MAX(nome)
       INTO v_nome_produto
       FROM tipo_produto
      WHERE tipo_produto_id = r_itn1.tipo_produto_id;
     --
     p_erro_cod := '90000';
     p_erro_msg := 'Produto não integrado com o Apolo (' || v_nome_produto || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_job_id IS NULL THEN
     -- carta acordo multijob. Pega valores da tabela item_carta.
     v_qtd_freq_char       := numero_apolo_mostrar(nvl(r_itn1.quantidade, 0), 6, 'N');
     v_custo_unitario_char := numero_apolo_mostrar(nvl(r_itn1.custo_unitario, 0), 6, 'N');
     v_valor_item_char     := numero_apolo_mostrar(nvl(r_itn1.valor_aprovado, 0), 2, 'N');
    ELSE
     -- qtd lancada no item sempre igual a 1
     v_qtd_freq_char       := numero_apolo_mostrar(nvl(1, 0), 6, 'N');
     v_custo_unitario_char := numero_apolo_mostrar(nvl(r_itn1.valor_aprovado, 0), 6, 'N');
     v_valor_item_char     := numero_apolo_mostrar(nvl(r_itn1.valor_aprovado, 0), 2, 'N');
    END IF;
    --
    v_num_seq_it      := v_num_seq_it + 1;
    v_tipo_produto_id := r_itn1.tipo_produto_id;
    v_custo_unitario  := r_itn1.custo_unitario;
    --
    SELECT xmlconcat(xmlelement("ProdCodEstr", r_itn1.cod_ext_produto),
                     xmlelement("ItPedCompSeq", v_num_seq_it),
                     xmlelement("ItPedCompServ", decode(r_itn1.categoria_id, 'SER', 'Sim', 'Não')),
                     xmlelement("ItPedCompQtd", v_qtd_freq_char),
                     xmlelement("ItPedCompValUnit", v_custo_unitario_char),
                     xmlelement("ItPedCompValUnitLiq", v_custo_unitario_char),
                     xmlelement("ItPedCompValTot", v_valor_item_char),
                     xmlelement("ItPedCompPercAcrescFin", 0),
                     xmlelement("ItPedCompValAcrescFin", 0),
                     xmlelement("ItPedCompPercDescEspec",
                                numero_apolo_mostrar(v_perc_desconto, 4, 'N')),
                     xmlelement("ItPedCompValDescEspec", 0),
                     xmlelement("ItPedCompAprovUsuCod", 'JOBONE'))
      INTO v_xml_conteudo_itens_aux1
      FROM dual;
    --
    v_xml_conteudo_itens_aux2 := NULL;
    v_num_seq_job             := 0;
    --
    -- monta o rateio do produto/item por job
    FOR r_itn2 IN c_itn2
    LOOP
     v_valor_rateio := r_itn2.valor;
     v_num_seq_job  := v_num_seq_job + 1;
     --
     IF v_perc_desconto > 0 THEN
      v_valor_rateio := round(r_itn2.valor * (1 - v_perc_desconto / 100), 2);
     END IF;
     --
     -- acumula os valores rateados de todos os itens para verificacao de
     -- arredondamento
     v_valor_acum := v_valor_acum + v_valor_rateio;
     --
     -- guarda o valor do ultimo rateio e os ultimos numeros sequenciais
     -- do produto/item e do job
     v_valor_ult_rateio := v_valor_rateio;
     v_num_ult_seq_it   := v_num_seq_it;
     v_num_ult_seq_job  := v_num_seq_job;
     --
     SELECT xmlagg(xmlelement("row_RATEIO_ITEM_PED_COMP",
                              xmlelement("CCtrlCodAlt", r_itn2.num_job),
                              xmlelement("RatItPedCompVal",
                                         numero_apolo_mostrar(v_valor_rateio, 2, 'N'))))
       INTO v_xml_conteudo_itens_aux22
       FROM dual;
     --
     SELECT xmlconcat(v_xml_conteudo_itens_aux2, v_xml_conteudo_itens_aux22)
       INTO v_xml_conteudo_itens_aux2
       FROM dual;
    END LOOP;
    --
    SELECT xmlagg(xmlelement("RATEIO_ITEM_PED_COMP", v_xml_conteudo_itens_aux2))
      INTO v_xml_conteudo_itens_aux2
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_itens_aux1, v_xml_conteudo_itens_aux2)
      INTO v_xml_conteudo_itens_aux
      FROM dual;
    --
    SELECT xmlagg(xmlelement("row", v_xml_conteudo_itens_aux))
      INTO v_xml_conteudo_itens_aux
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
      INTO v_xml_conteudo_itens
      FROM dual;
   END LOOP;
   --
   SELECT xmlagg(xmlelement("ITEM_PED_COMP", v_xml_conteudo_itens))
     INTO v_xml_conteudo_itens
     FROM dual;
   --
   IF v_valor_final <> v_valor_acum THEN
    -- precisa ajustar o ultimo rateio (recalcula usando a diferenca)
    v_valor_rateio := v_valor_ult_rateio + (v_valor_final - v_valor_acum);
    --
    SELECT updatexml(v_xml_conteudo_itens,
                     '/ITEM_PED_COMP/row[' || v_num_ult_seq_it ||
                     ']/RATEIO_ITEM_PED_COMP/row_RATEIO_ITEM_PED_COMP[' || v_num_ult_seq_job ||
                     ']/RatItPedCompVal/text()',
                     numero_apolo_mostrar(v_valor_rateio, 2, 'N'))
      INTO v_xml_conteudo_itens
      FROM dual;
   END IF;
   --
   ------------------------------------------------------------
   -- monta a secao "parcelas"
   ------------------------------------------------------------
   --
   FOR r_par IN c_par
   LOOP
    IF r_par.data_parcela IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela não informada (' || to_char(r_par.num_parcela) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT xmlagg(xmlelement("row",
                             xmlelement("ParcPagPedCompDataVenc",
                                        data_apolo_mostrar(r_par.data_parcela)),
                             xmlelement("ParcPagPedCompVal",
                                        numero_apolo_mostrar(nvl(r_par.valor_parcela, 0), 2, 'N')),
                             xmlelement("ParcPagPedCompNumDup", r_par.num_parcela)))
      INTO v_xml_conteudo_parc_aux
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_parc, v_xml_conteudo_parc_aux)
      INTO v_xml_conteudo_parc
      FROM dual;
   END LOOP;
   --
   SELECT xmlagg(xmlelement("PARC_PAG_PED_COMP", v_xml_conteudo_parc))
     INTO v_xml_conteudo_parc
     FROM dual;
   --
   ------------------------------------------------------------
   -- junta o conteudo com os itens e parcelas
   ------------------------------------------------------------
   SELECT xmlconcat(v_xml_conteudo,
                    v_xml_conteudo_itens,
                    xmlelement("CondPagCod", nvl(v_cod_ext_condicao, '0000003')),
                    v_xml_conteudo_parc)
     INTO v_xml_conteudo
     FROM dual;
   --
   SELECT xmlagg(xmlelement("PED_COMP", v_xml_conteudo))
     INTO v_xml_mensagem
     FROM dual;
  END IF; -- fim do  IF TRIM(p_cod_acao) IN ('I','A')
  --
  IF TRIM(p_cod_acao) = 'E' THEN
   SELECT xmlagg(xmlelement("DELETAR_PED_COMP",
                            xmlelement("pedido_compra", v_cod_ext_carta),
                            xmlelement("EmpCPFCNPJ", v_cnpj_cpf),
                            xmlelement("Entidade", v_cod_ext_fornecedor)))
     INTO v_xml_mensagem
     FROM dual;
  END IF;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  -- chama a procedure de integracao
  apolo_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'CARTA_ACORDO',
                 p_cod_acao,
                 p_carta_acordo_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- processamento final
  ------------------------------------------------------------
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out, '/PED_COMP_RETORNO/PedCompNum'))
     INTO v_cod_ext_carta
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_carta) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Apolo da carta acordo (pedido de compra).';
    RAISE v_exception;
   END IF;
   --
   UPDATE carta_acordo
      SET cod_ext_carta = TRIM(v_cod_ext_carta)
    WHERE carta_acordo_id = p_carta_acordo_id;
  END IF;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END carta_acordo_integrar;
 --
 --
 --
 PROCEDURE faturamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/07/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de faturamento.
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
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_xml_cabecalho          xmltype;
  v_xml_conteudo           xmltype;
  v_xml_mensagem           xmltype;
  v_xml_conteudo_itens     xmltype;
  v_xml_conteudo_itens_aux xmltype;
  v_xml_out                CLOB;
  v_xml_in                 CLOB;
  v_operacao               VARCHAR2(500);
  v_cod_ext_fatur          faturamento.cod_ext_fatur%TYPE;
  v_data_ordem             faturamento.data_ordem%TYPE;
  v_data_vencim            faturamento.data_vencim%TYPE;
  v_cliente_fat_id         faturamento.cliente_id%TYPE;
  v_cod_natureza_oper      faturamento.cod_natureza_oper%TYPE;
  v_descricao              faturamento.descricao%TYPE;
  v_obs                    faturamento.obs%TYPE;
  v_flag_bv                faturamento.flag_bv%TYPE;
  v_emp_faturar_por_id     faturamento.emp_faturar_por_id%TYPE;
  v_valor_fatura           NUMBER;
  v_cliente_fat            pessoa.apelido%TYPE;
  v_apelido_emp_fatur      pessoa.apelido%TYPE;
  v_cod_ext_cliente        pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_emp_fat        pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_num_seq                INTEGER;
  v_custo_unitario_char    VARCHAR2(100);
  --
  CURSOR c_itn IS
   SELECT jo.numero AS num_job,
          it.item_id,
          it.natureza_item,
          it.tipo_item,
          it.num_seq,
          nvl(ia.valor_fatura, 0) AS valor_fatura,
          tp.cod_ext_produto AS cod_ext_produto
     FROM item_fatur   ia,
          item         it,
          tipo_produto tp,
          job          jo
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.job_id = jo.job_id
      AND it.tipo_produto_id = tp.tipo_produto_id
    ORDER BY it.tipo_item,
             it.num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  SELECT fa.cliente_id,
         cl.apelido,
         fa.cod_ext_fatur,
         fa.data_ordem,
         fa.data_vencim,
         faturamento_pkg.valor_fatura_retornar(fa.faturamento_id),
         fa.descricao,
         fa.obs,
         fa.cod_natureza_oper,
         fa.flag_bv,
         fa.emp_faturar_por_id
    INTO v_cliente_fat_id,
         v_cliente_fat,
         v_cod_ext_fatur,
         v_data_ordem,
         v_data_vencim,
         v_valor_fatura,
         v_descricao,
         v_obs,
         v_cod_natureza_oper,
         v_flag_bv,
         v_emp_faturar_por_id
    FROM faturamento fa,
         pessoa      cl
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.cliente_id = cl.pessoa_id;
  --
  SELECT apelido
    INTO v_apelido_emp_fatur
    FROM pessoa
   WHERE pessoa_id = v_emp_faturar_por_id;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_emp_fat
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_emp_faturar_por_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo IN ('CLIENTE', 'FORNECEDOR');
  --
  IF v_cod_ext_emp_fat IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa de faturamento não está integrada com o Apolo (' || v_apelido_emp_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_cliente
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_fat_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo IN ('CLIENTE', 'FORNECEDOR');
  --
  IF v_cod_ext_cliente IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O cliente desse faturamento não está integrado com o Apolo (' || v_cliente_fat || ').';
   RAISE v_exception;
  END IF;
  --
  v_obs := char_esp_apolo_retirar(v_obs);
  v_obs := upper(acento_retirar(v_obs));
  --
  ------------------------------------------------------------
  -- processamento do faturamento
  ------------------------------------------------------------
  --
  -- monta a secao "conteudo"
  SELECT xmlconcat(xmlelement("Empresa", v_cod_ext_emp_fat),
                   xmlelement("Numero", to_char(p_faturamento_id)),
                   xmlelement("TipoNota", 'Saída'),
                   xmlelement("Entidade", v_cod_ext_cliente),
                   xmlelement("NaturezadeOperacao", v_cod_natureza_oper),
                   xmlelement("Observacao", v_obs),
                   xmlelement("StatusdoPedido", 'Operacional'),
                   xmlelement("CondicaodeRecebimento", 'A vista'),
                   xmlelement("CodigodoUsuarioVendedor", 'JOBONE'),
                   xmlelement("CodigodoUsuarioAtendentenoSistema", 'JOBONE'))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "itens"
  ------------------------------------------------------------
  v_num_seq := 0;
  --
  FOR r_itn IN c_itn
  LOOP
   v_num_seq := v_num_seq + 1;
   --
   v_custo_unitario_char := numero_apolo_mostrar(nvl(r_itn.valor_fatura, 0), 6, 'N');
   --
   SELECT xmlagg(xmlelement("Item_Ped_Venda",
                            xmlelement("Sequencia", to_char(v_num_seq)),
                            xmlelement("Quantidade", '1'),
                            xmlelement("Produto", r_itn.cod_ext_produto),
                            xmlelement("UnidadedeMedida", 'UN'),
                            xmlelement("ValorUnitario", v_custo_unitario_char),
                            xmlelement("NaturezadeOperacaoItem", v_cod_natureza_oper),
                            xmlelement("IndiceEconomico", 'R$'),
                            xmlelement("DescricaoNotaFiscal", NULL),
                            xmlelement("CentroControleItemPedido", r_itn.num_job)))
     INTO v_xml_conteudo_itens_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
     INTO v_xml_conteudo_itens
     FROM dual;
  END LOOP;
  --
  ------------------------------------------------------------
  -- junta o header do conteudo com os itens
  ------------------------------------------------------------
  SELECT xmlconcat(v_xml_conteudo, v_xml_conteudo_itens)
    INTO v_xml_conteudo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("Ped_Venda", v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  -- chama a procedure de integracao
  apolo_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'FATURAMENTO',
                 p_cod_acao,
                 p_faturamento_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- processamento final
  ------------------------------------------------------------
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out, '/PED_COMP_RETORNO/CodigoPedidoApolo'))
     INTO v_cod_ext_fatur
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_fatur) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código Apolo do faturamento (pedido de venda).';
    RAISE v_exception;
   END IF;
   --
   UPDATE faturamento
      SET cod_ext_fatur = TRIM(v_cod_ext_fatur)
    WHERE faturamento_id = p_faturamento_id;
  END IF;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END faturamento_integrar;
 --
 --
 --
 PROCEDURE apolo_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 11/04/2013
  -- DESCRICAO: Subrotina que executa a chamada de webservices no sistema APOLO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/06/2017  Novo parametro objeto_id
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
  v_qt          INTEGER;
  v_exception   EXCEPTION;
  v_xml_log_id  xml_log.xml_log_id%TYPE;
  v_status_ret  VARCHAR2(20);
  v_caminho_ret VARCHAR2(100);
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
  IF TRIM(p_cod_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'JOBONE', 'APOLO', p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  IF p_cod_objeto = 'CARTA_ACORDO' THEN
   IF p_cod_acao IN ('I', 'A') THEN
    v_caminho_ret := '/PED_COMP_RETORNO';
   ELSE
    v_caminho_ret := '/DELETAR_PED_COMP_RETORNO';
   END IF;
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'cartaAcordoIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
  ELSIF p_cod_objeto = 'FATURAMENTO' THEN
   IF p_cod_acao IN ('I', 'A') THEN
    v_caminho_ret := '/PED_VENDA_RETORNO';
   ELSE
    v_caminho_ret := '/DELETAR_PED_VENDA_RETORNO';
   END IF;
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'faturamentoIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_erro_msg) IS NOT NULL THEN
   p_erro_cod := '90000';
   RAISE v_exception;
  END IF;
  --
  -- recupera o status retornado
  SELECT MAX(extractvalue(xml_out, v_caminho_ret || '/Codigo'))
    INTO v_status_ret
    FROM (SELECT xmltype(p_xml_out) AS xml_out
            FROM dual);
  --
  v_status_ret := TRIM(upper(v_status_ret));
  --
  IF v_status_ret <> '0' THEN
   SELECT MAX(extractvalue(xml_out, v_caminho_ret || '/Erros/row[1]/DescricaoErro'))
     INTO p_erro_msg
     FROM (SELECT xmltype(p_xml_out) AS xml_out
             FROM dual);
   --
   p_erro_cod := '90000';
   RAISE v_exception;
  ELSIF v_status_ret IS NULL THEN
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
   p_erro_msg := 'APOLO: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'APOLO - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END apolo_executar;
 --
 --
 --
 FUNCTION data_apolo_mostrar
 -----------------------------------------------------------------------
  --   DATA_MOSTRAR
  --
  --   Descricao: funcao que converte uma data para o formato CHAR
  -----------------------------------------------------------------------
 (p_data IN DATE) RETURN VARCHAR2 IS
  --
  v_ok   INTEGER;
  v_data VARCHAR2(10);
  --
 BEGIN
  v_ok   := 0;
  v_data := to_char(p_data, 'yyyy-mm-dd');
  v_ok   := 1;
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_data := 'Erro DATA';
   RETURN v_data;
 END data_apolo_mostrar;
 --
 --
 --
 FUNCTION data_apolo_converter
 -----------------------------------------------------------------------
  --   DATA_APOLO_CONVERTER
  --
  --   Descricao: funcao que converte um string contendo uma data no
  --   formato 'YYYYMMDD'.
  -----------------------------------------------------------------------
 (p_data IN VARCHAR2) RETURN DATE IS
  --
  v_data DATE;
  --
 BEGIN
  v_data := NULL;
  v_data := to_date(REPLACE(p_data, '-', ''), 'yyyymmdd');
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data;
 END data_apolo_converter;
 --
 --
 --
 FUNCTION data_apolo_validar
 -----------------------------------------------------------------------
  --   DATA_APOLO_VALIDAR
  --
  --   Descricao: funcao que consiste um string contendo uma data no
  --   formato 'YYYYMMDD'. Retorna '1' caso o string seja
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
  v_data := to_date(REPLACE(p_data, '-', ''), 'yyyymmdd');
  IF rtrim(p_data) IS NOT NULL THEN
   v_ano := to_number(to_char(v_data, 'yyyy'));
   IF v_ano > 1000 THEN
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
 END data_apolo_validar;
 --
 --
 --
 FUNCTION numero_apolo_converter
 -----------------------------------------------------------------------
  --   NUMERO_APOLO_CONVERTER
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
 END numero_apolo_converter;
 --
 --
 --
 FUNCTION numero_apolo_validar
 -----------------------------------------------------------------------
  --   NUMERO_APOLO_VALIDAR
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
  IF instr(p_numero, ',') > 0 THEN
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
 END numero_apolo_validar;
 --
 --
 FUNCTION numero_apolo_mostrar
 -----------------------------------------------------------------------
  --   NUMERO_APOLO_MOSTRAR
  --
  --   Descricao: funcao que converte um Number em um String com seguinte
  --   formato '99999999999999999999.999999' (ate 6 casas decimais,
  --   dependendo do numero de casas decimais especificado).
  -----------------------------------------------------------------------
 (
  p_numero      IN NUMBER,
  p_casas_dec   IN INTEGER,
  p_flag_milhar IN VARCHAR2
 ) RETURN VARCHAR2 IS
  v_ok     INTEGER;
  v_numero VARCHAR2(30);
 BEGIN
  --
  IF p_casas_dec IS NULL OR p_casas_dec >= 6 OR p_casas_dec < 0 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D000000',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D000000', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 5 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D00000',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D00000', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 4 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D0000',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D0000', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 3 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D000',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D000', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 2 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D00',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D00', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 1 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D0',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D0', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  ELSIF p_casas_dec = 0 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero, '99G999G999G999G999G999G990', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
   END IF;
  END IF;
  --
  /*
    IF v_numero IS NULL THEN
       v_numero := '0';
    END IF;
  */
  --
  RETURN v_numero;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_numero;
 END numero_apolo_mostrar;
 --
--
END; -- IT_APOLO_PKG

/
