--------------------------------------------------------
--  DDL for Package Body IT_CIGAM_ANT_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_CIGAM_ANT_PKG" IS
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
  -- Silvia            23/03/2018  Novo parametro objeto_id
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
  -- Silvia            23/03/2018  Novo parametro objeto_id
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
 FUNCTION char_esp_cigam_retirar
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
 END char_esp_cigam_retirar;
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
  p_processo           IN VARCHAR2,
  p_cod_acao           IN VARCHAR2,
  p_xml_cabecalho      OUT xmltype,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_data_hora       VARCHAR2(40);
  v_operacao        VARCHAR2(100);
  v_uuid            VARCHAR2(50);
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
  v_data_hora := to_char(SYSDATE, 'yyyymmdd') || ' ' || to_char(SYSDATE, 'hh24mi');
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'incluir';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'alterar';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'excluir';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  v_uuid := uuid_retornar;
  --
  SELECT xmlagg(xmlelement("cabecalho",
                           xmlelement("servico", p_processo),
                           xmlelement("operacao", v_operacao),
                           xmlelement("transacao", v_uuid),
                           xmlelement("data_hora", v_data_hora),
                           xmlelement("codigo_empresa", v_cod_ext_empresa)))
    INTO p_xml_cabecalho
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_CIGAM_PKG(ret_cabec): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_CIGAM_PKG(ret_cabec): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
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
  p_servico            IN VARCHAR2,
  p_operacao           IN VARCHAR2,
  p_transacao          IN VARCHAR2,
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
  v_data_hora := to_char(SYSDATE, 'yyyymmdd') || ' ' || to_char(SYSDATE, 'hh24:mi');
  --
  SELECT xmlagg(xmlelement("cabecalho",
                           xmlelement("servico", p_servico),
                           xmlelement("operacao", p_operacao),
                           xmlelement("transacao", p_transacao),
                           xmlelement("data_hora", v_data_hora)))
    INTO p_xml_cabecalho
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_CIGAM_PKG(ret_cabec): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_CIGAM_PKG(ret_cabec): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
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
  SELECT xmlagg(xmlelement("retorno",
                           xmlelement("codigo", p_cod_retorno),
                           xmlelement("mensagem", p_mensagem)))
    INTO p_xml_resposta
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_CIGAM_PKG(ret_msg): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_CIGAM_PKG(ret_msg): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
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
  p_servico            IN VARCHAR2,
  p_operacao           IN VARCHAR2,
  p_transacao          IN VARCHAR2,
  p_cod_retorno        IN VARCHAR2,
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
                      p_servico,
                      p_operacao,
                      p_transacao,
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
                    v_mensagem,
                    v_xml_resposta,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_resposta))
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
   p_erro_msg := 'IT_CIGAM_PKG(retorno): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_CIGAM_PKG(retorno): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END xml_retorno_gerar;
 --
 --
 --
 PROCEDURE nf_saida_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 23/06/2014
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do CIGAM referentes a
  --  integração nota fiscal de saida.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_xml_in   IN CLOB,
  p_xml_out  OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
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
  v_cod_acao           VARCHAR2(20);
  v_operacao           VARCHAR2(20);
  v_servico            VARCHAR2(40);
  v_transacao          VARCHAR2(40);
  v_nota_fiscal_id     nota_fiscal.nota_fiscal_id%TYPE;
  v_emp_emissora_id    nota_fiscal.emp_emissora_id%TYPE;
  v_num_doc            nota_fiscal.num_doc%TYPE;
  v_num_serie          nota_fiscal.serie%TYPE;
  v_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_tipo_doc_nf_id     nota_fiscal.tipo_doc_nf_id%TYPE;
  v_data_pri_vencim    nota_fiscal.data_pri_vencim%TYPE;
  v_valor_bruto        nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_aux    nota_fiscal.valor_bruto%TYPE;
  v_emp_cnpj           pessoa.cnpj%TYPE;
  v_job_id             job.job_id%TYPE;
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_cod_ext_fatur      faturamento.cod_ext_fatur%TYPE;
  v_tipo_doc_nf        tipo_doc_nf.codigo%TYPE;
  v_valor_fatura       NUMBER;
  v_tipo_doc           VARCHAR2(20);
  v_valor_bruto_char   VARCHAR2(20);
  v_data_vencim_char   VARCHAR2(20);
  v_doc_identif        VARCHAR2(100);
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  p_xml_out  := NULL;
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
  log_gravar(v_xml_log_id, 'CIGAM', 'JOBONE', 'NF_SAIDA', NULL, NULL, p_xml_in);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'CIGAM_ONZE';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (CIGAM_ONZE).';
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
  SELECT TRIM(extractvalue(v_xml_in, '/conteudo/cabecalho/servico')),
         TRIM(extractvalue(v_xml_in, '/conteudo/cabecalho/operacao')),
         TRIM(extractvalue(v_xml_in, '/conteudo/cabecalho/transacao'))
    INTO v_servico,
         v_operacao,
         v_transacao
    FROM dual;
  --
  IF v_servico IS NULL OR upper(v_servico) <> 'NF_SAIDA_PROCESSAR' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do produto inválido (' || v_servico || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_operacao IS NULL OR upper(v_operacao) NOT IN ('INFORMAR', 'CANCELAR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da operação inválido (' || v_operacao || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_transacao IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da transação não informado.';
   RAISE v_exception;
  END IF;
  --
  IF upper(v_operacao) = 'INFORMAR' THEN
   v_cod_acao := 'INCLUIR';
  ELSIF upper(v_operacao) = 'CANCELAR' THEN
   v_cod_acao := 'EXCLUIR';
  END IF;
  --
  ------------------------------------------------------------
  -- extracao do corpo
  ------------------------------------------------------------
  SELECT TRIM(extractvalue(v_xml_in, '/conteudo/corpo/codigo_externo_faturamento')),
         TRIM(extractvalue(v_xml_in, '/conteudo/corpo/numero')),
         TRIM(extractvalue(v_xml_in, '/conteudo/corpo/serie')),
         TRIM(extractvalue(v_xml_in, '/conteudo/corpo/tipo_documento')),
         TRIM(extractvalue(v_xml_in, '/conteudo/corpo/valor_bruto')),
         TRIM(extractvalue(v_xml_in, '/conteudo/corpo/data_vencimento'))
    INTO v_cod_ext_fatur,
         v_num_doc,
         v_num_serie,
         v_tipo_doc,
         v_valor_bruto_char,
         v_data_vencim_char
    FROM dual;
  --
  SELECT MAX(faturamento_id)
    INTO v_faturamento_id
    FROM faturamento
   WHERE cod_ext_fatur = v_cod_ext_fatur;
  --
  IF v_faturamento_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem de faturamento não encontrada (' || v_cod_ext_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT em.empresa_id,
         em.nome,
         fa.emp_faturar_por_id,
         fa.cliente_id,
         jo.job_id
    INTO v_empresa_id,
         v_nome_empresa,
         v_emp_emissora_id,
         v_cliente_id,
         v_job_id
    FROM faturamento fa,
         job         jo,
         empresa     em
   WHERE fa.faturamento_id = v_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.empresa_id = em.empresa_id;
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
   p_erro_msg := 'O número da nota fiscal de saída não pode ter mais que 10 caracteres (' ||
                 v_num_doc || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(v_num_serie) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A série da nota fiscal de saída não pode ter mais que 10 caracteres (' ||
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
  IF v_data_vencim_char IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de vencimento da nota fiscal de saída é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF data_cigam_validar(v_data_vencim_char) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento da nota fiscal de saída inválida (' || v_data_vencim_char || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_pri_vencim := data_cigam_converter(v_data_vencim_char);
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
  IF numero_cigam_validar(v_valor_bruto_char) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal de saída inválido (' || v_doc_identif ||
                 ' Valor bruto: ' || v_valor_bruto_char || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_bruto := numero_cigam_converter(v_valor_bruto_char);
  --
  ------------------------------------------------------------
  -- processamento da exclusao
  ------------------------------------------------------------
  IF v_cod_acao = 'EXCLUIR' THEN
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
    p_erro_msg := 'Valor bruto da nota fiscal de saída não confere (' ||
                  ' Valor bruto JobOne: ' || moeda_mostrar(v_valor_bruto_aux, 'S') ||
                  ' Valor bruto CIGAM:' || moeda_mostrar(v_valor_bruto, 'S') || ').';
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
  IF v_cod_acao = 'INCLUIR' THEN
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
   v_valor_fatura := faturamento_pkg.valor_fatura_retornar(v_faturamento_id);
   --
   IF nvl(v_valor_bruto, 0) <> v_valor_fatura THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor bruto da nota fiscal de saída (' ||
                  moeda_mostrar(v_valor_bruto, 'S') ||
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
     status)
   VALUES
    (v_nota_fiscal_id,
     v_job_id,
     v_cliente_id,
     v_emp_emissora_id,
     'S',
     v_tipo_doc_nf_id,
     TRIM(v_num_doc),
     TRIM(v_num_serie),
     SYSDATE,
     trunc(SYSDATE),
     v_data_pri_vencim,
     v_valor_bruto,
     0,
     'CONC');
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
  END IF; -- fim do IF v_operacao
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc_nf || ': ' ||
                      TRIM(v_num_doc) || ' ' || TRIM(v_num_serie);
  v_compl_histor   := 'Integração CIGAM';
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'NOTA_FISCAL',
                   v_cod_acao,
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
                    v_servico,
                    v_operacao,
                    v_transacao,
                    p_erro_cod,
                    p_erro_msg,
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
                     v_servico,
                     v_operacao,
                     v_transacao,
                     p_erro_cod,
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
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
   ROLLBACK;
 END nf_saida_processar;
 --
 --
 PROCEDURE job_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/04/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_xml_cabecalho   xmltype;
  v_xml_corpo       xmltype;
  v_xml_conteudo    xmltype;
  v_xml_out         CLOB;
  v_xml_in          CLOB;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_nome_empresa    empresa.nome%TYPE;
  v_nome_cliente    pessoa.nome%TYPE;
  v_cliente_id      pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa  pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id          job.job_id%TYPE;
  v_num_job         job.numero%TYPE;
  v_nome_job        job.nome%TYPE;
  v_cod_ext_job     job.cod_ext_job%TYPE;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT cl.pessoa_id,
         cl.nome,
         jo.job_id,
         jo.numero,
         jo.nome,
         jo.cod_ext_job
    INTO v_cliente_id,
         v_nome_cliente,
         v_job_id,
         v_num_job,
         v_nome_job,
         v_cod_ext_job
    FROM job    jo,
         pessoa cl
   WHERE jo.job_id = p_job_id
     AND jo.cliente_id = cl.pessoa_id;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente ainda não está integrado (' || v_nome_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- processamento de JOB
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  xml_env_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'job_integrar',
                      p_cod_acao,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "corpo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("corpo",
                           xmlelement("codigo_externo_job", v_cod_ext_job),
                           xmlelement("numero", v_num_job),
                           xmlelement("nome", v_nome_job),
                           xmlelement("codigo_externo_cliente", v_cod_ext_pessoa),
                           xmlelement("job_id", p_job_id)))
    INTO v_xml_corpo
    FROM dual;
  --
  -- junta o cabecalho com o corpo
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_corpo))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  cigam_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'JOB',
                 p_cod_acao,
                 p_job_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo do job
   SELECT MAX(extractvalue(xml_out, '/conteudo/retorno/codigo_externo_job'))
     INTO v_cod_ext_job
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_job IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código CIGAM do job.';
    RAISE v_exception;
   END IF;
   --
   UPDATE job
      SET cod_ext_job = v_cod_ext_job
    WHERE job_id = p_job_id;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END job_integrar;
 --
 --
 PROCEDURE orcamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 09/05/2017
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de ORCAMENTO com o
  --   CIGAM, como se fosse um projeto/job (usa o mesmo XML do job).
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
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_xml_cabecalho   xmltype;
  v_xml_corpo       xmltype;
  v_xml_conteudo    xmltype;
  v_xml_out         CLOB;
  v_xml_in          CLOB;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_nome_empresa    empresa.nome%TYPE;
  v_nome_cliente    pessoa.nome%TYPE;
  v_cliente_id      pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa  pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id          job.job_id%TYPE;
  v_num_job         job.numero%TYPE;
  v_nome_job        job.nome%TYPE;
  v_cod_ext_job     job.cod_ext_job%TYPE;
  v_cod_ext_orcam   orcamento.cod_ext_orcam%TYPE;
  v_num_estim       VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT cl.pessoa_id,
         cl.nome,
         jo.job_id,
         jo.numero,
         jo.nome,
         jo.cod_ext_job
    INTO v_cliente_id,
         v_nome_cliente,
         v_job_id,
         v_num_job,
         v_nome_job,
         v_cod_ext_job
    FROM job       jo,
         pessoa    cl,
         orcamento oc
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id
     AND jo.cliente_id = cl.pessoa_id;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente ainda não está integrado (' || v_nome_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_estim := orcamento_pkg.numero_formatar(p_orcamento_id);
  --
  ------------------------------------------------------------
  -- processamento de JOB
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  xml_env_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'job_integrar',
                      p_cod_acao,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "corpo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("corpo",
                           xmlelement("codigo_externo_job", v_cod_ext_orcam),
                           xmlelement("numero", v_num_estim),
                           xmlelement("nome", v_nome_job),
                           xmlelement("codigo_externo_cliente", v_cod_ext_pessoa),
                           xmlelement("job_id", v_num_estim)))
    INTO v_xml_corpo
    FROM dual;
  --
  -- junta o cabecalho com o corpo
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_corpo))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  cigam_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'ORCAMENTO',
                 p_cod_acao,
                 p_orcamento_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo do job
   SELECT MAX(extractvalue(xml_out, '/conteudo/retorno/codigo_externo_job'))
     INTO v_cod_ext_job
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_job IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código CIGAM do job/estimativa.';
    RAISE v_exception;
   END IF;
   --
   UPDATE orcamento
      SET cod_ext_orcam = v_cod_ext_orcam
    WHERE orcamento_id = p_orcamento_id;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END orcamento_integrar;
 --
 --
 --
 PROCEDURE pessoa_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/04/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de PESSOA.
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
  v_saida              EXCEPTION;
  v_xml_cabecalho      xmltype;
  v_xml_corpo          xmltype;
  v_xml_conteudo       xmltype;
  v_xml_out            CLOB;
  v_xml_in             CLOB;
  v_cod_ext_empresa    empresa_sist_ext.cod_ext_empresa%TYPE;
  v_nome_empresa       empresa.nome%TYPE;
  v_cod_ext_pessoa     pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_pessoa_nome        pessoa.nome%TYPE;
  v_pessoa_apelido     pessoa.apelido%TYPE;
  v_cidade             pessoa.cidade%TYPE;
  v_tipo_conta         pessoa.tipo_conta%TYPE;
  v_cod_banco          fi_banco.codigo%TYPE;
  v_flag_cliente       CHAR(1);
  v_flag_fornec        CHAR(1);
  v_flag_pessoa_ex     CHAR(1);
  v_tipo_pessoa_cli_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_for_id tipo_pessoa.tipo_pessoa_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.cidade,
         ba.codigo,
         pe.tipo_conta,
         pe.nome,
         pe.apelido
    INTO v_cidade,
         v_cod_banco,
         v_tipo_conta,
         v_pessoa_nome,
         v_pessoa_apelido
    FROM pessoa   pe,
         fi_banco ba
   WHERE pe.pessoa_id = p_pessoa_id
     AND pe.fi_banco_id = ba.fi_banco_id(+);
  --
  SELECT MAX(cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext
   WHERE pessoa_id = p_pessoa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_cli_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_for_id
    FROM tipo_pessoa
   WHERE codigo = 'FORNECEDOR';
  --
  v_cidade := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade := char_especial_retirar(v_cidade);
  --
  v_pessoa_nome    := char_especial_retirar(v_pessoa_nome);
  v_pessoa_apelido := char_especial_retirar(v_pessoa_apelido);
  --
  IF v_cod_banco IS NULL THEN
   v_tipo_conta := NULL;
  END IF;
  --
  v_flag_cliente   := 'N';
  v_flag_fornec    := 'N';
  v_flag_pessoa_ex := 'N';
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'CLIENTE') = 1 THEN
   v_flag_cliente := 'S';
  END IF;
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'FORNECEDOR') = 1 THEN
   v_flag_fornec := 'S';
  END IF;
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'ESTRANGEIRO') = 1 THEN
   v_flag_pessoa_ex := 'S';
  END IF;
  ------------------------------------------------------------
  -- processamento de PESSOA
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  xml_env_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'pessoa_integrar',
                      p_cod_acao,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "corpo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("corpo",
                           xmlelement("codigo_externo_pessoa", v_cod_ext_pessoa),
                           xmlelement("flag_cliente", v_flag_cliente),
                           xmlelement("flag_fornecedor", v_flag_fornec),
                           xmlelement("apelido", v_pessoa_apelido),
                           xmlelement("nome", v_pessoa_nome),
                           xmlelement("flag_pessoa_jur", flag_pessoa_jur),
                           xmlelement("flag_pessoa_ex", v_flag_pessoa_ex),
                           xmlelement("cnpj", cnpj),
                           xmlelement("inscr_estadual",
                                      nvl(char_especial_retirar(TRIM(inscr_estadual)), 'ISENTO')),
                           xmlelement("inscr_municipal", char_especial_retirar(inscr_municipal)),
                           xmlelement("inscr_inss", char_especial_retirar(inscr_inss)),
                           xmlelement("cpf", cpf),
                           xmlelement("rg", rg),
                           xmlelement("rg_org_exp", rg_org_exp),
                           xmlelement("rg_data_exp", data_cigam_mostrar(rg_data_exp)),
                           xmlelement("rg_uf", rg_uf),
                           xmlelement("endereco", char_especial_retirar(endereco)),
                           xmlelement("num_ender", char_especial_retirar(num_ender)),
                           xmlelement("compl_ender", char_especial_retirar(compl_ender)),
                           xmlelement("zona", char_especial_retirar(zona)),
                           xmlelement("bairro", char_especial_retirar(bairro)),
                           xmlelement("cep", char_especial_retirar(cep)),
                           xmlelement("cidade", v_cidade),
                           xmlelement("uf", uf),
                           xmlelement("pais",
                                      decode(upper(TRIM(pais)),
                                             NULL,
                                             'BRA',
                                             'BRASIL',
                                             'BRA',
                                             pais)),
                           xmlelement("ddd_telefone", char_especial_retirar(ddd_telefone)),
                           xmlelement("num_telefone", char_especial_retirar(num_telefone)),
                           xmlelement("num_ramal", char_especial_retirar(num_ramal)),
                           xmlelement("ddd_celular", char_especial_retirar(ddd_celular)),
                           xmlelement("num_celular", char_especial_retirar(num_celular)),
                           xmlelement("website", website),
                           xmlelement("email", email),
                           xmlelement("tipo_conta", v_tipo_conta),
                           xmlelement("cod_banco", v_cod_banco),
                           xmlelement("num_agencia", char_especial_retirar(num_agencia)),
                           xmlelement("num_conta", char_especial_retirar(num_conta)),
                           xmlelement("nome_titular", char_especial_retirar(nome_titular)),
                           xmlelement("cnpj_cpf_titular",
                                      char_especial_retirar(cnpj_cpf_titular)),
                           xmlelement("pessoa_id", p_pessoa_id)))
    INTO v_xml_corpo
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- junta o cabecalho com o corpo
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_corpo))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  cigam_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'PESSOA',
                 p_cod_acao,
                 p_pessoa_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  DELETE FROM pessoa_sist_ext
   WHERE pessoa_id = p_pessoa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo da pessoa
   SELECT MAX(extractvalue(xml_out, '/conteudo/retorno/codigo_externo_pessoa'))
     INTO v_cod_ext_pessoa
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_ext_pessoa IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código CIGAM da pessoa.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_cliente = 'S' THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_cli_id,
      v_cod_ext_pessoa);
   END IF;
   --
   IF v_flag_fornec = 'S' THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_for_id,
      v_cod_ext_pessoa);
   END IF;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END pessoa_integrar;
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
  v_xml_corpo              xmltype;
  v_xml_conteudo           xmltype;
  v_xml_conteudo_itens     xmltype;
  v_xml_conteudo_itens_aux xmltype;
  v_xml_out                CLOB;
  v_xml_in                 CLOB;
  v_cod_ext_empresa        empresa_sist_ext.cod_ext_empresa%TYPE;
  v_nome_empresa           empresa.nome%TYPE;
  v_cod_ext_fatur          faturamento.cod_ext_fatur%TYPE;
  v_data_vencim            faturamento.data_vencim%TYPE;
  v_cliente_fat_id         faturamento.cliente_id%TYPE;
  v_cod_natureza_oper      faturamento.cod_natureza_oper%TYPE;
  v_descricao              faturamento.descricao%TYPE;
  v_flag_bv                faturamento.flag_bv%TYPE;
  v_valor_fatura           NUMBER;
  v_cliente_fat            pessoa.apelido%TYPE;
  v_cod_ext_cliente        pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_job            job.cod_ext_job%TYPE;
  --
  CURSOR c_itn IS
   SELECT decode(it.natureza_item, 'CUSTO', 'CUSTO', 'HONOR', 'HONOR', 'ENCARGO') AS natureza_item,
          nvl(SUM(ia.valor_fatura), 0) AS valor_fatura
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
    GROUP BY decode(it.natureza_item, 'CUSTO', 'CUSTO', 'HONOR', 'HONOR', 'ENCARGO');
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
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT fa.cliente_id,
         cl.apelido,
         fa.cod_ext_fatur,
         fa.data_vencim,
         faturamento_pkg.valor_fatura_retornar(fa.faturamento_id),
         fa.descricao,
         fa.cod_natureza_oper,
         fa.flag_bv,
         jo.cod_ext_job
    INTO v_cliente_fat_id,
         v_cliente_fat,
         v_cod_ext_fatur,
         v_data_vencim,
         v_valor_fatura,
         v_descricao,
         v_cod_natureza_oper,
         v_flag_bv,
         v_cod_ext_job
    FROM faturamento fa,
         pessoa      cl,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.cliente_id = cl.pessoa_id
     AND fa.job_id = jo.job_id;
  --
  IF v_cod_ext_job IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O job desse faturamento não está integrado com o CIGAM.';
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
   p_erro_msg := 'O cliente desse faturamento não está integrado com o CIGAM (' ||
                 v_cliente_fat || ').';
   RAISE v_exception;
  END IF;
  --
  v_descricao := char_esp_cigam_retirar(v_descricao);
  v_descricao := upper(acento_retirar(v_descricao));
  --
  ------------------------------------------------------------
  -- processamento do faturamento
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  xml_env_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'ordem_faturamento_integrar',
                      p_cod_acao,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "corpo"
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("codigo_externo_faturamento", v_cod_ext_fatur),
                   xmlelement("codigo_externo_job", v_cod_ext_job),
                   xmlelement("codigo_externo_cliente", v_cod_ext_cliente),
                   xmlelement("natureza_operacao", v_cod_natureza_oper),
                   xmlelement("data_vencimento", data_cigam_mostrar(v_data_vencim)),
                   xmlelement("descricao", v_descricao),
                   xmlelement("valor", numero_cigam_mostrar(v_valor_fatura, 2, 'N')),
                   xmlelement("faturamento_id", to_char(p_faturamento_id)))
    INTO v_xml_corpo
    FROM dual;
  --
  -- monta a secao "itens"
  FOR r_itn IN c_itn
  LOOP
   --
   SELECT xmlagg(xmlelement("item",
                            xmlelement("tipo", r_itn.natureza_item),
                            xmlelement("valor",
                                       numero_cigam_mostrar(r_itn.valor_fatura, 2, 'N'))))
     INTO v_xml_conteudo_itens_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
     INTO v_xml_conteudo_itens
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("itens", v_xml_conteudo_itens))
    INTO v_xml_conteudo_itens
    FROM dual;
  --
  -- junta o corpo com os itens
  SELECT xmlconcat(v_xml_corpo, v_xml_conteudo_itens)
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("corpo", v_xml_corpo))
    INTO v_xml_corpo
    FROM dual;
  --
  -- junta o cabecalho com o corpo
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_corpo))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  cigam_executar(p_sistema_externo_id,
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
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out, '/conteudo/retorno/codigo_externo_faturamento'))
     INTO v_cod_ext_fatur
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_fatur) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código CIGAM do faturamento.';
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END faturamento_integrar;
 --
 --
 --
 PROCEDURE nf_entrada_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/07/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de NF entrada.
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
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_saida              EXCEPTION;
  v_xml_cabecalho      xmltype;
  v_xml_corpo          xmltype;
  v_xml_conteudo       xmltype;
  v_xml_out            CLOB;
  v_xml_in             CLOB;
  v_cod_ext_empresa    empresa_sist_ext.cod_ext_empresa%TYPE;
  v_nome_empresa       empresa.nome%TYPE;
  v_cod_ext_nf         nota_fiscal.cod_ext_nf%TYPE;
  v_data_pri_vencim    nota_fiscal.data_pri_vencim%TYPE;
  v_data_entrada       nota_fiscal.data_entrada%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_fornecedor_id      nota_fiscal.emp_emissora_id%TYPE;
  v_valor_bruto        nota_fiscal.valor_bruto%TYPE;
  v_num_doc            nota_fiscal.num_doc%TYPE;
  v_serie              nota_fiscal.serie%TYPE;
  v_uf_servico         nota_fiscal.uf_servico%TYPE;
  v_municipio_servico  nota_fiscal.municipio_servico%TYPE;
  v_tipo_fatur_bv      nota_fiscal.tipo_fatur_bv%TYPE;
  v_cod_ext_doc        tipo_doc_nf.cod_ext_doc%TYPE;
  v_fornecedor         pessoa.apelido%TYPE;
  v_cod_ext_fornecedor pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_cod_ext_job        job.cod_ext_job%TYPE;
  v_job_id             job.job_id%TYPE;
  v_valor_bvtip        NUMBER;
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
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(it.job_id)
    INTO v_job_id
    FROM item_nota io,
         item      it
   WHERE io.nota_fiscal_id = p_nota_fiscal_id
     AND io.item_id = it.item_id;
  --
  SELECT nf.emp_emissora_id,
         fo.apelido,
         nf.cod_ext_nf,
         nf.data_pri_vencim,
         nf.data_entrada,
         nf.data_emissao,
         nf.valor_bruto,
         nf.num_doc,
         nf.serie,
         nf.uf_servico,
         nf.municipio_servico,
         nvl(td.cod_ext_doc, td.codigo),
         nf.tipo_fatur_bv
    INTO v_fornecedor_id,
         v_fornecedor,
         v_cod_ext_nf,
         v_data_pri_vencim,
         v_data_entrada,
         v_data_emissao,
         v_valor_bruto,
         v_num_doc,
         v_serie,
         v_uf_servico,
         v_municipio_servico,
         v_cod_ext_doc,
         v_tipo_fatur_bv
    FROM nota_fiscal nf,
         pessoa      fo,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = fo.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  SELECT MAX(cod_ext_job)
    INTO v_cod_ext_job
    FROM job
   WHERE job_id = v_job_id;
  --
  IF v_cod_ext_job IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O job dessa nota fiscal não está integrado com o CIGAM.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_fornecedor
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_fornecedor_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo IN ('CLIENTE', 'FORNECEDOR');
  --
  IF v_cod_ext_fornecedor IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor dessa nota fiscal não está integrado com o CIGAM (' ||
                 v_fornecedor || ').';
   RAISE v_exception;
  END IF;
  --
  v_municipio_servico := upper(acento_retirar(v_municipio_servico));
  v_valor_bvtip       := 0;
  --
  SELECT nvl(SUM(valor_bv), 0) + nvl(SUM(valor_tip), 0)
    INTO v_valor_bvtip
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_tipo_fatur_bv = 'ABA' THEN
   v_valor_bruto := v_valor_bruto - v_valor_bvtip;
  END IF;
  --
  ------------------------------------------------------------
  -- processamento da nota fiscal
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  xml_env_cabec_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'ordem_pagamento_integrar',
                      p_cod_acao,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "corpo"
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("codigo_externo_pagamento", v_cod_ext_nf),
                   xmlelement("codigo_externo_job", v_cod_ext_job),
                   xmlelement("codigo_externo_fornecedor", v_cod_ext_fornecedor),
                   xmlelement("numero_documento", v_num_doc),
                   xmlelement("serie", v_serie),
                   xmlelement("tipo_documento", v_cod_ext_doc),
                   xmlelement("data_emissao", data_cigam_mostrar(v_data_emissao)),
                   xmlelement("data_entrada", data_cigam_mostrar(v_data_entrada)),
                   xmlelement("data_primeiro_venc", data_cigam_mostrar(v_data_pri_vencim)),
                   xmlelement("valor_bruto", numero_cigam_mostrar(v_valor_bruto, 2, 'N')),
                   xmlelement("uf_prestacao_servico", v_uf_servico),
                   xmlelement("cidade_prestacao_servico", v_municipio_servico),
                   xmlelement("nota_fiscal_id", to_char(p_nota_fiscal_id)))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("corpo", v_xml_corpo))
    INTO v_xml_corpo
    FROM dual;
  --
  -- junta o cabecalho com o corpo
  SELECT xmlagg(xmlelement("conteudo", v_xml_cabecalho, v_xml_corpo))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  cigam_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'NF_ENTRADA',
                 p_cod_acao,
                 p_nota_fiscal_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out, '/conteudo/retorno/codigo_externo_pagamento'))
     INTO v_cod_ext_nf
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_nf) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código CIGAM da nota fiscal.';
    RAISE v_exception;
   END IF;
   --
   UPDATE nota_fiscal
      SET cod_ext_nf = TRIM(v_cod_ext_nf)
    WHERE nota_fiscal_id = p_nota_fiscal_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END nf_entrada_integrar;
 --
 --
 --
 PROCEDURE cigam_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 11/04/2013
  -- DESCRICAO: Subrotina que executa a chamada de webservices no sistema CIGAM.
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
  log_gravar(v_xml_log_id, 'JOBONE', 'CIGAM', p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --p_erro_cod := '90000';
  --p_erro_msg := 'TESTE CIGAM.';
  --
  IF p_cod_objeto = 'PESSOA' THEN
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pessoaIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
  ELSIF p_cod_objeto = 'JOB' THEN
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'jobIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
  ELSIF p_cod_objeto = 'NF_ENTRADA' THEN
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'ordemPagamentoIntegrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
  ELSIF p_cod_objeto = 'FATURAMENTO' THEN
   --
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'ordemFaturamentoIntegrar',
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
  v_caminho_ret := '/conteudo/retorno';
  --
  -- recupera o status retornado
  SELECT MAX(extractvalue(xml_out, v_caminho_ret || '/codigo'))
    INTO v_status_ret
    FROM (SELECT xmltype(p_xml_out) AS xml_out
            FROM dual);
  --
  v_status_ret := TRIM(upper(v_status_ret));
  --
  IF v_status_ret <> '00000' THEN
   SELECT MAX(extractvalue(xml_out, v_caminho_ret || '/mensagem'))
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
   p_erro_msg := 'CIGAM: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'CIGAM - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        500);
 END cigam_executar;
 --
 --
 --
 FUNCTION data_cigam_mostrar
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
  v_data := to_char(p_data, 'yyyymmdd');
  v_ok   := 1;
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_data := 'Erro DATA';
   RETURN v_data;
 END data_cigam_mostrar;
 --
 --
 --
 FUNCTION data_cigam_converter
 -----------------------------------------------------------------------
  --   DATA_CIGAM_CONVERTER
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
  v_data := to_date(p_data, 'yyyymmdd');
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data;
 END data_cigam_converter;
 --
 --
 --
 FUNCTION data_cigam_validar
 -----------------------------------------------------------------------
  --   DATA_CIGAM_VALIDAR
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
  v_data := to_date(p_data, 'yyyymmdd');
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
 END data_cigam_validar;
 --
 --
 --
 FUNCTION numero_cigam_converter
 -----------------------------------------------------------------------
  --   NUMERO_CIGAM_CONVERTER
  --
  --   Descricao: função que converte um string previamente validado
  --   em numero. O string pdeve estar tanto no formato
  --   '99999999999999999999,99999'
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
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
  --
  RETURN v_numero;
 EXCEPTION
  WHEN OTHERS THEN
   v_numero := 99999999;
   RETURN v_numero;
 END numero_cigam_converter;
 --
 --
 --
 FUNCTION numero_cigam_validar
 -----------------------------------------------------------------------
  --   NUMERO_CIGAM_VALIDAR
  --
  --   Descricao: funcao que consiste uma string nos seguintes
  --   formatos moeda '99999999999999999999,99'.
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
  IF instr(p_numero, '.') > 0 THEN
   RETURN v_ok;
  END IF;
  --
  v_numero_char := rtrim(REPLACE(p_numero, '.', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
  v_ok     := 1;
  --
  RETURN v_ok;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END numero_cigam_validar;
 --
 --
 FUNCTION numero_cigam_mostrar
 -----------------------------------------------------------------------
  --   NUMERO_CIGAM_MOSTRAR
  --
  --   Descricao: funcao que converte um Number em um String com seguinte
  --   formato '99999999999999999999,999999' (ate 6 casas decimais,
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
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero,
                        '99999999999999999990D000000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 5 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D00000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero,
                        '99999999999999999990D00000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 4 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D0000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero,
                        '99999999999999999990D0000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 3 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero,
                        '99999999999999999990D000',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 2 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D00',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero,
                        '99999999999999999990D00',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 1 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990D0',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990D0', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
   END IF;
  ELSIF p_casas_dec = 0 THEN
   IF p_flag_milhar = 'S' THEN
    v_numero := to_char(p_numero,
                        '99G999G999G999G999G999G990',
                        'NLS_NUMERIC_CHARACTERS = '',.'' ');
   ELSE
    v_numero := to_char(p_numero, '99999999999999999990', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
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
 END numero_cigam_mostrar;
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
END; -- IT_CIGAM_PKG

/
