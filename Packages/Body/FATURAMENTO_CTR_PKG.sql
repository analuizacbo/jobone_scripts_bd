--------------------------------------------------------
--  DDL for Package Body FATURAMENTO_CTR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FATURAMENTO_CTR_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 31/08/2018
  -- DESCRICAO: Comanda o faturamento de parcelas do contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/04/2019  Novo atributo ordem_compra
  -- Silvia            26/02/2021  Novo parametro para usar ou nao data vencim
  -- Silvia            31/01/2022  Novo parametro flag_pula_integr
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_contrato_id               IN faturamento_ctr.contrato_id%TYPE,
  p_vetor_parcela_contrato_id IN VARCHAR2,
  p_vetor_valor_fatura        IN VARCHAR2,
  p_emp_faturar_por_id        IN faturamento_ctr.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper         IN faturamento_ctr.cod_natureza_oper%TYPE,
  p_ordem_compra              IN faturamento.ordem_compra%TYPE,
  p_cliente_id                IN faturamento_ctr.cliente_id%TYPE,
  p_contato_cli_id            IN faturamento_ctr.contato_cli_id%TYPE,
  p_data_vencim               IN VARCHAR2,
  p_descricao                 IN VARCHAR2,
  p_obs                       IN VARCHAR2,
  p_flag_patrocinio           IN VARCHAR2,
  p_flag_outras_receitas      IN VARCHAR2,
  p_tipo_receita              IN VARCHAR2,
  p_municipio_servico         IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico                IN nota_fiscal.uf_servico%TYPE,
  p_flag_pula_integr          IN VARCHAR2,
  p_faturamento_ctr_id        OUT faturamento_ctr.faturamento_ctr_id%TYPE,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
  v_qt                        INTEGER;
  v_identif_objeto            historico.identif_objeto%TYPE;
  v_compl_histor              historico.complemento%TYPE;
  v_historico_id              historico.historico_id%TYPE;
  v_exception                 EXCEPTION;
  v_numero_contrato           contrato.numero%TYPE;
  v_faturamento_ctr_id        faturamento_ctr.faturamento_ctr_id%TYPE;
  v_data_vencim               faturamento_ctr.data_vencim%TYPE;
  v_valor_total               NUMBER;
  v_delimitador               CHAR(1);
  v_vetor_parcela_contrato_id VARCHAR2(4000);
  v_vetor_valor_fatura        VARCHAR2(4000);
  v_valor_fatura_char         VARCHAR2(20);
  v_valor_fatura              parcela_fatur_ctr.valor_fatura%TYPE;
  v_valor_a_faturar           parcela_fatur_ctr.valor_fatura%TYPE;
  v_parcela_contrato_id       parcela_fatur_ctr.parcela_contrato_id%TYPE;
  v_xml_atual                 CLOB;
  v_flag_usar_data            VARCHAR2(10);
  --
 BEGIN
  v_qt                 := 0;
  p_faturamento_ctr_id := 0;
  v_flag_usar_data     := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_DATA_VENCIM_FATUR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_FATUR_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pula_integr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pula integração inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_cliente_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
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
  --
  IF rtrim(p_data_vencim) IS NULL AND v_flag_usar_data = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_vencim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa de faturamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id
     AND flag_emp_fatur = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_natureza_oper) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da natureza de operação para faturamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE pessoa_id = p_emp_faturar_por_id
     AND codigo = p_cod_natureza_oper;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Natureza de operação para faturamento inválida (' || p_cod_natureza_oper || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_ordem_compra)) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da Ordem de Compra não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_data_vencim := data_converter(p_data_vencim);
  --
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_patrocinio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag patrocínio inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_outras_receitas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag outras receitas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL THEN
   -- o tipo de receita foi especificado
   IF util_pkg.desc_retornar('tipo_receita', p_tipo_receita) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de receita inválida (' || p_tipo_receita || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_outras_receitas = 'N' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Um tipo de receita foi especificado mas a opção de ' ||
                  'Outras Receitas não está marcada.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_patrocinio = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível selecionar patrocínio e outras receitas ' || 'ao mesmo tempo.';
    RAISE v_exception;
   END IF;
  ELSE
   -- o tipo de receita nao foi especificado
   IF p_flag_outras_receitas = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A opção de Outras Receitas está marcada mas nenhum ' ||
                  'tipo de receita foi especificado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF (TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NULL) OR
     (TRIM(p_uf_servico) IS NULL AND TRIM(p_municipio_servico) IS NOT NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O local da prestação de produto está incompleto.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NOT NULL THEN
   IF cep_pkg.municipio_validar(p_uf_servico, p_municipio_servico) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do local da prestação de produto inválido (' || p_uf_servico || '/' ||
                  p_municipio_servico || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT numero
    INTO v_numero_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_faturamento.nextval
    INTO v_faturamento_ctr_id
    FROM dual;
  --
  INSERT INTO faturamento_ctr
   (faturamento_ctr_id,
    contrato_id,
    emp_faturar_por_id,
    cliente_id,
    contato_cli_id,
    usuario_fatur_id,
    data_vencim,
    data_ordem,
    descricao,
    obs,
    cod_natureza_oper,
    flag_patrocinio,
    tipo_receita,
    municipio_servico,
    uf_servico,
    ordem_compra)
  VALUES
   (v_faturamento_ctr_id,
    p_contrato_id,
    p_emp_faturar_por_id,
    p_cliente_id,
    zvl(p_contato_cli_id, NULL),
    p_usuario_sessao_id,
    v_data_vencim,
    trunc(SYSDATE),
    TRIM(p_descricao),
    TRIM(p_obs),
    TRIM(p_cod_natureza_oper),
    p_flag_patrocinio,
    TRIM(p_tipo_receita),
    TRIM(p_municipio_servico),
    TRIM(p_uf_servico),
    TRIM(p_ordem_compra));
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_valor_total               := 0;
  v_delimitador               := '|';
  v_vetor_parcela_contrato_id := p_vetor_parcela_contrato_id;
  v_vetor_valor_fatura        := p_vetor_valor_fatura;
  --
  WHILE nvl(length(rtrim(v_vetor_parcela_contrato_id)), 0) > 0
  LOOP
   v_parcela_contrato_id := to_number(prox_valor_retornar(v_vetor_parcela_contrato_id,
                                                          v_delimitador));
   v_valor_fatura_char   := prox_valor_retornar(v_vetor_valor_fatura, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM parcela_contrato
    WHERE parcela_contrato_id = v_parcela_contrato_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa parcela de contrato não existe (' || to_char(v_parcela_contrato_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_fatura_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor a faturar inválido (' || v_valor_fatura_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_fatura := nvl(moeda_converter(v_valor_fatura_char), 0);
   --
   IF v_valor_fatura < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor a faturar inválido (' || v_valor_fatura_char || ').';
    RAISE v_exception;
   END IF;
   --
   -- v_valor_a_faturar := faturamento_ctr_pkg.valor_retornar(v_parcela_contrato_id, 'AFATURAR');
   --
   IF v_valor_fatura > v_valor_a_faturar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor que está sendo faturado (' || moeda_mostrar(v_valor_fatura, 'S') ||
                  ') não pode exceder o restante a faturar (' ||
                  moeda_mostrar(v_valor_a_faturar, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------
   -- inclusao do detalhe do faturamento
   ------------------------------------------
   IF v_valor_fatura > 0 THEN
    INSERT INTO parcela_fatur_ctr
     (parcela_fatur_ctr_id,
      parcela_contrato_id,
      faturamento_ctr_id,
      valor_fatura)
    VALUES
     (seq_parcela_fatur_ctr.nextval,
      v_parcela_contrato_id,
      v_faturamento_ctr_id,
      v_valor_fatura);
   END IF;
   --
   v_valor_total := v_valor_total + v_valor_fatura;
  END LOOP;
  --
  IF v_valor_total = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor a faturar foi informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF p_flag_pula_integr = 'N' THEN
   it_controle_pkg.integrar('FATURAMENTO_ADICIONAR',
                            p_empresa_id,
                            v_faturamento_ctr_id,
                            'CONTRATO',
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faturamento_ctr_pkg.xml_gerar(v_faturamento_ctr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'Contrato: ' || to_char(v_numero_contrato) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO_CTR',
                   'INCLUIR',
                   v_identif_objeto,
                   v_faturamento_ctr_id,
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
  p_faturamento_ctr_id := v_faturamento_ctr_id;
  p_erro_cod           := '00000';
  p_erro_msg           := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END comandar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 31/08/2018
  -- DESCRICAO: Exclusão de FATURAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_numero_contrato    contrato.numero%TYPE;
  v_contrato_id        contrato.contrato_id%TYPE;
  v_data_vencim        faturamento_ctr.data_vencim%TYPE;
  v_valor_total        NUMBER;
  v_nota_fiscal_sai_id faturamento_ctr.nota_fiscal_sai_id%TYPE;
  v_xml_atual          CLOB;
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
    FROM faturamento_ctr fa,
         contrato        ct
   WHERE fa.faturamento_ctr_id = p_faturamento_ctr_id
     AND fa.contrato_id = ct.contrato_id
     AND ct.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.contrato_id,
         ct.numero,
         fa.data_vencim,
         fa.nota_fiscal_sai_id
    INTO v_contrato_id,
         v_numero_contrato,
         v_data_vencim,
         v_nota_fiscal_sai_id
    FROM faturamento_ctr fa,
         contrato        ct
   WHERE fa.faturamento_ctr_id = p_faturamento_ctr_id
     AND fa.contrato_id = ct.contrato_id;
  --
  IF p_flag_commit = 'S' THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_FATUR_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_nota_fiscal_sai_id IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento já tem nota fiscal de saída emitida.';
   RAISE v_exception;
  END IF;
  --
  SELECT SUM(valor_fatura)
    INTO v_valor_total
    FROM parcela_fatur_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  faturamento_ctr_pkg.xml_gerar(p_faturamento_ctr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('FATURAMENTO_EXCLUIR',
                           p_empresa_id,
                           p_faturamento_ctr_id,
                           'CONTRATO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM parcela_fatur_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  DELETE FROM faturamento_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'Contrato: ' || to_char(v_numero_contrato) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO_CTR',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_faturamento_ctr_id,
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
  IF p_flag_commit = 'S' THEN
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
 END excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/02/2017
  -- DESCRICAO: Subrotina que gera o xml do faturamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE,
  p_xml                OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_xml          xmltype;
  v_xml_aux1     xmltype;
  v_xml_aux99    xmltype;
  v_xml_doc      VARCHAR2(100);
  v_valor_fatura NUMBER;
  --
  CURSOR c_pa IS
   SELECT pa.num_parcela,
          numero_mostrar(pf.valor_fatura, 2, 'N') valor_fatura
     FROM parcela_fatur_ctr pf,
          parcela_contrato  pa
    WHERE pf.faturamento_ctr_id = p_faturamento_ctr_id
      AND pf.parcela_contrato_id = pa.parcela_contrato_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT nvl(SUM(valor_fatura), 0)
    INTO v_valor_fatura
    FROM parcela_fatur_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("faturamento_ctr_id", fa.faturamento_ctr_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("contrato", ct.numero),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("contato_cliente", co.apelido),
                   xmlelement("data_entrada", data_mostrar(fa.data_ordem)),
                   xmlelement("data_vencimento", data_mostrar(fa.data_vencim)),
                   xmlelement("empresa_fatur", ef.apelido),
                   xmlelement("natureza_oper", fa.cod_natureza_oper || '-' || na.descricao),
                   xmlelement("valor_fatura", numero_mostrar(v_valor_fatura, 2, 'S')),
                   xmlelement("patrocinio", fa.flag_patrocinio),
                   xmlelement("tipo_receita",
                              util_pkg.desc_retornar('tipo_receita', fa.tipo_receita)),
                   xmlelement("municipio_servico", fa.municipio_servico),
                   xmlelement("uf_servico", fa.uf_servico),
                   xmlelement("cod_ext_fatur", fa.cod_ext_fatur),
                   xmlelement("ordem_compra", fa.ordem_compra))
    INTO v_xml
    FROM faturamento_ctr     fa,
         pessoa              cl,
         pessoa              ef,
         contrato            ct,
         pessoa              co,
         natureza_oper_fatur na
   WHERE fa.faturamento_ctr_id = p_faturamento_ctr_id
     AND fa.cliente_id = cl.pessoa_id
     AND fa.emp_faturar_por_id = ef.pessoa_id
     AND fa.contrato_id = ct.contrato_id
     AND fa.contato_cli_id = co.pessoa_id(+)
     AND fa.emp_faturar_por_id = na.pessoa_id(+)
     AND fa.cod_natureza_oper = na.codigo(+);
  --
  ------------------------------------------------------------
  -- monta ITENS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlagg(xmlelement("parcela",
                            xmlelement("num_parcela", r_pa.num_parcela),
                            xmlelement("valor_parcela", r_pa.valor_fatura)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("parcelas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "faturamento_ctr"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("faturamento_ctr", v_xml))
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
 FUNCTION valor_fatura_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor total de uma determinada ordem de faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(SUM(valor_fatura), 0)
    INTO v_retorno
    FROM parcela_fatur_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_fatura_retornar;
 --
 --
 FUNCTION parcelas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 31/08/2018
  -- DESCRICAO: retorna as parcelas associadas a um determinado faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt        INTEGER;
  v_retorno   VARCHAR2(4000);
  v_exception EXCEPTION;
  --
  CURSOR c_fa IS
   SELECT DISTINCT pa.num_parcela,
                   se.nome AS nome_servico
     FROM parcela_fatur_ctr pf,
          parcela_contrato  pa,
          contrato_servico  cs,
          servico           se
    WHERE pf.faturamento_ctr_id = p_faturamento_ctr_id
      AND pf.parcela_contrato_id = pa.parcela_contrato_id
      AND pa.contrato_servico_id = cs.contrato_servico_id(+)
      AND cs.servico_id = se.servico_id(+)
    ORDER BY num_parcela;
  --
 BEGIN
  v_retorno := NULL;
  --
  FOR r_fa IN c_fa
  LOOP
   IF r_fa.nome_servico IS NOT NULL THEN
    v_retorno := v_retorno || ', ' || 'Parcela ' || to_char(r_fa.num_parcela) || ' (' ||
                 r_fa.nome_servico || ')';
   ELSE
    v_retorno := v_retorno || ', ' || 'Parcela ' || to_char(r_fa.num_parcela);
   END IF;
  END LOOP;
  --
  -- retira a primeira virgula
  v_retorno := substr(v_retorno, 3);
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END parcelas_retornar;
 --
--
END; -- FATURAMENTO_CTR_PKG

/
