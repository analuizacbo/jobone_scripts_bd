--------------------------------------------------------
--  DDL for Package Body CONTRATO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CONTRATO_PKG" IS
 --
 g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 --
 --
 PROCEDURE resp_int_tratar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/05/2020
  -- DESCRICAO: subrotina que verifica se o usuario pode ser responsavel
  --   interno e, caso o contrato nao tenha nenhum, marca como responsavel. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_contrato_id IN contrato.contrato_id%TYPE,
  p_usuario_id  IN usuario.usuario_id%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_empresa_id contrato.empresa_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao
  ------------------------------------------------------------
  -- verifica se o contrato ja tem responsavel interno
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_usuario
   WHERE contrato_id = p_contrato_id
     AND flag_responsavel = 'S';
  --
  IF v_qt = 0 THEN
   -- contrato sem responsavel interno.
   -- verifica se esse usuario tem privilegio de responsavel interno
   SELECT empresa_id
     INTO v_empresa_id
     FROM contrato
    WHERE contrato_id = p_contrato_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'CONTRATO_RESP_INT_V', NULL, NULL, v_empresa_id) = 1 THEN
    UPDATE contrato_usuario
       SET flag_responsavel = 'S'
     WHERE contrato_id = p_contrato_id
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
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/09/2014
  -- DESCRICAO: Inclusão de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/06/2016  Novo parametro p_contrato_ori_id (usado p/ copia)
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            07/08/2019  Numero do contrato passou a ser unico geral.
  -- Henrique          16/08/2019  Novo parametro p_tipo_mensal_vigencia (Mensal/Vigência)
  -- Silvia            15/10/2019  Retirada do parceiro_id
  -- Silvia            18/01/2021  Retirada de tipo_mensal_vigencia
  -- José Mario        04/11/2022  Inclusão chamada da procedure CONTRATO_ELAB_PKG
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_ori_id   IN contrato.contrato_id%TYPE,
  p_tipo_contrato_id  IN contrato.tipo_contrato_id%TYPE,
  p_cod_ext_contrato  IN contrato.cod_ext_contrato%TYPE,
  p_nome              IN contrato.nome%TYPE,
  p_contratante_id    IN contrato.contratante_id%TYPE,
  p_contato_id        IN contrato.contato_id%TYPE,
  p_emp_resp_id       IN contrato.emp_resp_id%TYPE,
  p_data_assinatura   IN VARCHAR2,
  p_data_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_flag_renovavel    IN VARCHAR2,
  p_objeto            IN contrato.objeto%TYPE,
  p_ordem_compra      IN contrato.ordem_compra%TYPE,
  p_cod_ext_ordem     IN contrato.cod_ext_ordem%TYPE,
  p_contrato_id       OUT contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_contrato_id       contrato.contrato_id%TYPE;
  v_numero_contrato   contrato.numero%TYPE;
  v_flag_pago_cliente contrato.flag_pago_cliente%TYPE;
  v_data_assinatura   contrato.data_assinatura%TYPE;
  v_data_inicio       contrato.data_inicio%TYPE;
  v_data_termino      contrato.data_termino%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_atual         CLOB;
  v_flag_usar_servico VARCHAR2(10);
  --
  -- seleciona valor padrao das naturezas definido para o contratante,
  -- ou pega o valor padrao do sistema.
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          nvl(pn.valor_padrao, na.valor_padrao) valor_padrao
     FROM pessoa_nitem_pdr pn,
          natureza_item    na
    WHERE na.empresa_id = p_empresa_id
      AND na.codigo <> 'CUSTO'
      AND na.flag_ativo = 'S'
      AND na.natureza_item_id = pn.natureza_item_id(+)
      AND pn.pessoa_id(+) = p_contratante_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt                := 0;
  p_contrato_id       := 0;
  v_flag_usar_servico := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_CONTRATO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_I', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_contrato_ori_id, 0) > 0 THEN
   -- copia de contrato
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato
    WHERE contrato_id = p_contrato_ori_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Contrato copiado não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF nvl(p_tipo_contrato_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contratante_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contratante é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_contratante_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contratante não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao r
    WHERE r.pessoa_pai_id = p_contratante_id
      AND r.pessoa_filho_id = p_contato_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato não está associado a esse contratante.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF v_flag_usar_servico = 'N' THEN
   IF nvl(p_emp_resp_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_resp_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável não existe.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF data_validar(p_data_assinatura) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de assinatura inválida (' || p_data_assinatura || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do início da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da vigência inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_assinatura := data_converter(p_data_assinatura);
  v_data_inicio     := data_converter(p_data_inicio);
  v_data_termino    := data_converter(p_data_termino);
  --
  IF v_data_inicio > v_data_termino THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência não pode ser maior que a data de término (' ||
                 p_data_inicio || ' - ' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_renovavel) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag renovável inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_pago_cliente
    INTO v_flag_pago_cliente
    FROM pessoa
   WHERE pessoa_id = p_contratante_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(numero), 0) + 1
    INTO v_numero_contrato
    FROM contrato;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE numero = v_numero_contrato;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de contrato já existe (' || v_numero_contrato ||
                 '). Tente novamente.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_contrato.nextval
    INTO v_contrato_id
    FROM dual;
  --
  INSERT INTO contrato
   (contrato_id,
    empresa_id,
    tipo_contrato_id,
    contratante_id,
    contato_id,
    emp_resp_id,
    usuario_solic_id,
    numero,
    nome,
    cod_ext_contrato,
    objeto,
    data_entrada,
    data_inicio,
    data_termino,
    flag_renovavel,
    status,
    data_status,
    perc_bv,
    flag_bv_fornec,
    flag_pago_cliente,
    flag_bloq_negoc,
    ordem_compra,
    cod_ext_ordem,
    perc_desc,
    status_parcel)
  VALUES
   (v_contrato_id,
    p_empresa_id,
    p_tipo_contrato_id,
    p_contratante_id,
    zvl(p_contato_id, NULL),
    zvl(p_emp_resp_id, NULL),
    p_usuario_sessao_id,
    v_numero_contrato,
    TRIM(p_nome),
    TRIM(p_cod_ext_contrato),
    p_objeto,
    SYSDATE,
    v_data_inicio,
    v_data_termino,
    p_flag_renovavel,
    'PREP',
    trunc(SYSDATE),
    NULL,
    'S',
    v_flag_pago_cliente,
    'N',
    TRIM(p_ordem_compra),
    TRIM(p_cod_ext_ordem),
    0,
    'NAOI');
  --
  ------------------------------------------------------------
  -- instancia os valores padrao das naturezas dos itens
  ------------------------------------------------------------
  FOR r_na IN c_na
  LOOP
   INSERT INTO contrato_nitem_pdr
    (contrato_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_contrato_id,
     r_na.natureza_item_id,
     r_na.valor_padrao);

  END LOOP;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  contrato_pkg.enderecar_automatico(p_usuario_sessao_id,
                                    p_empresa_id,
                                    v_contrato_id,
                                    p_erro_cod,
                                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- copia de estimativa de horas
  ------------------------------------------------------------
  IF nvl(p_contrato_ori_id, 0) > 0 THEN
   INSERT INTO contrato_horas
    (contrato_horas_id,
     contrato_id,
     usuario_id,
     nivel,
     horas_planej,
     custo_hora_pdr,
     venda_hora_pdr,
     venda_hora_rev,
     venda_fator_ajuste,
     cargo_id,
     area_id,
     descricao,
     data)
    SELECT seq_contrato_horas.nextval,
           v_contrato_id,
           usuario_id,
           nivel,
           horas_planej,
           custo_hora_pdr,
           venda_hora_pdr,
           venda_hora_rev,
           venda_fator_ajuste,
           cargo_id,
           area_id,
           descricao,
           data
      FROM contrato_horas
     WHERE contrato_id = p_contrato_ori_id;

  END IF;
  --
  ------------------------------------------------------------
  -- Cria registros na CONTRATO_ELAB
  ------------------------------------------------------------
  contrato_elab_pkg.adicionar(p_usuario_sessao_id,
                              p_empresa_id,
                              v_contrato_id,
                              'TODOS',
                              'N',
                              p_erro_cod,
                              p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_contrato_id,
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
  IF v_data_assinatura IS NOT NULL THEN
   contrato_pkg.assinado_marcar(p_usuario_sessao_id,
                                'N',
                                p_empresa_id,
                                v_contrato_id,
                                p_data_assinatura,
                                p_erro_cod,
                                p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  p_contrato_id := v_contrato_id;
  p_erro_cod    := '00000';
  p_erro_msg    := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de contrato já existe (' || v_numero_contrato ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE adicionar_simples
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 23/07/2019
  -- DESCRICAO: subrotina de Inclusao simplificada de CONTRATO (usada em oportunidade).
  --   NAO FAZ COMMIT
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/08/2019  Numero do contrato passou a ser unico geral.
  -- Henrique          16/08/2019  Duro no insert campo tipo_mensal_vigencia (Mensal/Vigência)
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Silvia            15/05/2020  Eliminacao do vetor de papeis
  -- Silvia            28/05/2020  Novo vetor usuario resp contrato
  -- Silvia            18/01/2021  Retirada de tipo_mensal_vigencia
  -- Silvia            05/04/2021  Novo parametro flag_ctr_fisico
  -- Silvia            10/05/2021  Novo parametro cpf
  -- Silvia            17/02/2022  Notificacao de contrato fisico
  -- Silvia            26/12/2022  Inclusão chamada da procedure CONTRATO_ELAB_PKG
  -- Ana Luiaz         25/10/2024  Adicionado chave pix quando adiciona em pessoa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN contrato.empresa_id%TYPE,
  p_tipo_contrato_id      IN contrato.tipo_contrato_id%TYPE,
  p_emp_resp_id           IN contrato.emp_resp_id%TYPE,
  p_nome                  IN contrato.nome%TYPE,
  p_cli_flag_pessoa_jur   IN VARCHAR2,
  p_cli_flag_exterior     IN VARCHAR2,
  p_cli_flag_sem_docum    IN VARCHAR2,
  p_cli_apelido           IN VARCHAR2,
  p_cli_nome              IN VARCHAR2,
  p_cli_cnpj              IN VARCHAR2,
  p_cli_cpf               IN VARCHAR2,
  p_cli_endereco          IN VARCHAR2,
  p_cli_num_ender         IN VARCHAR2,
  p_cli_compl_ender       IN VARCHAR2,
  p_cli_bairro            IN VARCHAR2,
  p_cli_cep               IN VARCHAR2,
  p_cli_cidade            IN VARCHAR2,
  p_cli_uf                IN VARCHAR2,
  p_cli_pais              IN VARCHAR2,
  p_cli_email             IN VARCHAR2,
  p_cli_ddd_telefone      IN VARCHAR2,
  p_cli_num_telefone      IN VARCHAR2,
  p_cli_nome_setor        IN VARCHAR2,
  p_data_inicio           IN VARCHAR2,
  p_data_termino          IN VARCHAR2,
  p_flag_renovavel        IN VARCHAR2,
  p_flag_ctr_fisico       IN VARCHAR2,
  p_vetor_ender_empresas  IN VARCHAR2,
  p_vetor_ender_usuarios  IN VARCHAR2,
  p_vetor_ender_flag_resp IN VARCHAR2,
  p_contrato_id           OUT contrato.contrato_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS

  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_empresa_id            empresa.empresa_id%TYPE;
  v_nome_emp              empresa.nome%TYPE;
  v_contrato_id           contrato.contrato_id%TYPE;
  v_numero_contrato       contrato.numero%TYPE;
  v_data_inicio           contrato.data_inicio%TYPE;
  v_data_termino          contrato.data_termino%TYPE;
  v_contratante_id        contrato.contratante_id%TYPE;
  v_tipo_contrato_id      contrato.tipo_contrato_id%TYPE;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_cod_tipo_contrato     tipo_contrato.codigo%TYPE;
  v_xml_atual             CLOB;
  v_vetor_ender_empresas  VARCHAR2(1000);
  v_vetor_ender_usuarios  VARCHAR2(1000);
  v_vetor_ender_flag_resp VARCHAR2(1000);
  v_delimitador           CHAR(1);
  v_usuario_id            usuario.usuario_id%TYPE;
  v_unidade_negocio_id    unidade_negocio.unidade_negocio_id%TYPE;
  v_flag_responsavel      VARCHAR2(20);
  v_flag_usar_servico     VARCHAR2(10);
  v_setor_id              setor.setor_id%TYPE;
  v_chave_pix             pessoa.chave_pix%TYPE;
  --
  -- seleciona valor padrao das naturezas definido para o contratante,
  -- ou pega o valor padrao do sistema.
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          nvl(pn.valor_padrao, na.valor_padrao) valor_padrao
     FROM pessoa_nitem_pdr pn,
          natureza_item    na
    WHERE na.empresa_id = p_empresa_id
      AND na.codigo <> 'CUSTO'
      AND na.flag_ativo = 'S'
      AND na.natureza_item_id = pn.natureza_item_id(+)
      AND pn.pessoa_id(+) = v_contratante_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt                := 0;
  p_contrato_id       := 0;
  v_flag_usar_servico := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_CONTRATO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_emp
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_contrato_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- recupera o codigo pois o tipo pode ser de outra empresa
  SELECT MAX(codigo)
    INTO v_cod_tipo_contrato
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  IF v_cod_tipo_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de contrato não existe (' || to_char(p_tipo_contrato_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_contrato_id)
    INTO v_tipo_contrato_id
    FROM tipo_contrato
   WHERE codigo = v_cod_tipo_contrato
     AND empresa_id = p_empresa_id;
  --
  IF v_tipo_contrato_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de contrato ' || v_cod_tipo_contrato || ' não existe na empresa ' ||
                 v_nome_emp || '.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usar_servico = 'N' THEN
   IF nvl(p_emp_resp_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da empresa responsável pelo contrato é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_resp_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável (' || to_char(p_emp_resp_id) ||
                  ') não existe na empresa ' || v_nome_emp || '.';

    RAISE v_exception;
   END IF;

  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_cli_flag_exterior = 'N' AND (TRIM(p_cli_cnpj) IS NULL AND TRIM(p_cli_cpf) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contratante é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do início da vigência do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência do contrato inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término da vigência do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da vigência do contrato inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_renovavel) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag renovável inválido (' || p_flag_renovavel || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ctr_fisico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag contrato físico inválido (' || p_flag_ctr_fisico || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_inicio  := data_converter(p_data_inicio);
  v_data_termino := data_converter(p_data_termino);
  --
  IF v_data_inicio > v_data_termino THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência do contrato não pode ser maior que a data de término (' ||
                 p_data_inicio || ' - ' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verifica se precisa criar o setor na empresa do contrato
  ------------------------------------------------------------
  IF TRIM(p_cli_nome_setor) IS NOT NULL THEN
   SELECT MAX(setor_id)
     INTO v_setor_id
     FROM setor
    WHERE empresa_id = p_empresa_id
      AND upper(nome) = upper(TRIM(p_cli_nome_setor));
   --
   IF v_setor_id IS NULL THEN
    SELECT seq_setor.nextval
      INTO v_setor_id
      FROM dual;
    --
    INSERT INTO setor
     (setor_id,
      empresa_id,
      nome,
      codigo,
      flag_ativo)
    VALUES
     (v_setor_id,
      p_empresa_id,
      TRIM(p_cli_nome_setor),
      NULL,
      'S');

   END IF;

  END IF;
  --
  ------------------------------------------------------------
  -- verifica se precisa criar o cliente/contratante
  ------------------------------------------------------------
  IF p_cli_flag_exterior = 'N' THEN
   -- cliente no Brasil. Pesquisa pelo CNPJ/CPF.
   IF TRIM(p_cli_cnpj) IS NOT NULL THEN
    SELECT MAX(pessoa_id),
           MAX(TRIM(chave_pix))
      INTO v_contratante_id,
           v_chave_pix --251024
      FROM pessoa
     WHERE cnpj = p_cli_cnpj
       AND empresa_id = p_empresa_id;

   ELSE
    SELECT MAX(pessoa_id),
           MAX(TRIM(chave_pix))
      INTO v_contratante_id,
           v_chave_pix --251024
      FROM pessoa
     WHERE cpf = p_cli_cpf
       AND empresa_id = p_empresa_id;

   END IF;
  ELSE
   -- cliente no estrangeiro. Pesquisa pelo nome.
   SELECT MAX(pessoa_id)
     INTO v_contratante_id
     FROM pessoa
    WHERE upper(nome) = upper(TRIM(p_cli_nome))
      AND empresa_id = p_empresa_id;

  END IF;
  --
  IF v_contratante_id IS NULL THEN
   SELECT seq_pessoa.nextval
     INTO v_contratante_id
     FROM dual;
   --
   INSERT INTO pessoa
    (empresa_id,
     pessoa_id,
     apelido,
     nome,
     cnpj,
     cpf,
     flag_pessoa_jur,
     flag_sem_docum,
     flag_ativo,
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
     pais,
     setor_id,
     chave_pix)
   VALUES
    (p_empresa_id,
     v_contratante_id,
     TRIM(p_cli_apelido),
     TRIM(p_cli_nome),
     TRIM(p_cli_cnpj),
     TRIM(p_cli_cpf),
     p_cli_flag_pessoa_jur,
     p_cli_flag_sem_docum,
     'S',
     TRIM(p_cli_endereco),
     TRIM(p_cli_num_ender),
     TRIM(p_cli_compl_ender),
     TRIM(p_cli_bairro),
     TRIM(p_cli_cep),
     TRIM(p_cli_uf),
     TRIM(p_cli_cidade),
     TRIM(p_cli_email),
     TRIM(p_cli_ddd_telefone),
     TRIM(p_cli_num_telefone),
     TRIM(p_cli_pais),
     v_setor_id,
     v_chave_pix);

  ELSE
   UPDATE pessoa
      SET apelido         = TRIM(p_cli_apelido),
          nome            = TRIM(p_cli_nome),
          flag_pessoa_jur = p_cli_flag_pessoa_jur,
          flag_sem_docum  = p_cli_flag_sem_docum,
          endereco        = TRIM(p_cli_endereco),
          num_ender       = TRIM(p_cli_num_ender),
          compl_ender     = TRIM(p_cli_compl_ender),
          bairro          = TRIM(p_cli_bairro),
          cep             = TRIM(p_cli_cep),
          uf              = TRIM(p_cli_uf),
          cidade          = TRIM(p_cli_cidade),
          email           = TRIM(p_cli_email),
          ddd_telefone    = TRIM(p_cli_ddd_telefone),
          num_telefone    = TRIM(p_cli_num_telefone),
          pais            = TRIM(p_cli_pais),
          setor_id        = v_setor_id
    WHERE pessoa_id = v_contratante_id;

  END IF;
  --
  INSERT INTO tipific_pessoa tf
   (pessoa_id,
    tipo_pessoa_id)
   SELECT v_contratante_id,
          tipo_pessoa_id
     FROM tipo_pessoa tp
    WHERE codigo = 'CLIENTE'
      AND NOT EXISTS (SELECT 1
             FROM tipific_pessoa tf
            WHERE tf.pessoa_id = v_contratante_id
              AND tipo_pessoa_id = tp.tipo_pessoa_id);
  --
  IF p_cli_flag_exterior = 'S' THEN
   INSERT INTO tipific_pessoa tf
    (pessoa_id,
     tipo_pessoa_id)
    SELECT v_contratante_id,
           tipo_pessoa_id
      FROM tipo_pessoa tp
     WHERE codigo = 'ESTRANGEIRO'
       AND NOT EXISTS (SELECT 1
              FROM tipific_pessoa tf
             WHERE tf.pessoa_id = v_contratante_id
               AND tipo_pessoa_id = tp.tipo_pessoa_id);

  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(numero), 0) + 1
    INTO v_numero_contrato
    FROM contrato;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE numero = v_numero_contrato;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de contrato já existe (' || v_numero_contrato ||
                 '). Tente novamente.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_contrato.nextval
    INTO v_contrato_id
    FROM dual;
  --
  INSERT INTO contrato
   (contrato_id,
    empresa_id,
    tipo_contrato_id,
    contratante_id,
    emp_resp_id,
    usuario_solic_id,
    numero,
    nome,
    data_entrada,
    data_inicio,
    data_termino,
    flag_renovavel,
    flag_ctr_fisico,
    status,
    data_status,
    flag_bv_fornec,
    flag_pago_cliente,
    flag_bloq_negoc,
    perc_desc,
    status_parcel)
  VALUES
   (v_contrato_id,
    p_empresa_id,
    p_tipo_contrato_id,
    v_contratante_id,
    zvl(p_emp_resp_id, NULL),
    p_usuario_sessao_id,
    v_numero_contrato,
    TRIM(p_nome),
    SYSDATE,
    v_data_inicio,
    v_data_termino,
    p_flag_renovavel,
    p_flag_ctr_fisico,
    'PREP',
    trunc(SYSDATE),
    'S',
    'N',
    'N',
    0,
    'NAOI');
  --
  ------------------------------------------------------------
  -- instancia os valores padrao das naturezas dos itens
  ------------------------------------------------------------
  FOR r_na IN c_na
  LOOP
   INSERT INTO contrato_nitem_pdr
    (contrato_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_contrato_id,
     r_na.natureza_item_id,
     r_na.valor_padrao);

  END LOOP;
  --
  ------------------------------------------------------------
  -- Cria registros na CONTRATO_ELAB
  ------------------------------------------------------------
  contrato_elab_pkg.adicionar(p_usuario_sessao_id,
                              p_empresa_id,
                              v_contrato_id,
                              'TODOS',
                              'N',
                              p_erro_cod,
                              p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento manual
  ------------------------------------------------------------
  v_delimitador           := '|';
  v_vetor_ender_empresas  := rtrim(p_vetor_ender_empresas);
  v_vetor_ender_usuarios  := rtrim(p_vetor_ender_usuarios);
  v_vetor_ender_flag_resp := rtrim(p_vetor_ender_flag_resp);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_ender_empresas)), 0) > 0
  LOOP
   v_empresa_id       := nvl(to_number(prox_valor_retornar(v_vetor_ender_empresas, v_delimitador)),
                             0);
   v_usuario_id       := nvl(to_number(prox_valor_retornar(v_vetor_ender_usuarios, v_delimitador)),
                             0);
   v_flag_responsavel := prox_valor_retornar(v_vetor_ender_flag_resp, v_delimitador);
   --
   IF flag_validar(v_flag_responsavel) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag responsável inválido (' || v_flag_responsavel || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_empresa_id = p_empresa_id THEN
    -- so processa se for da mesma empresa do contrato
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario
     WHERE usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM contrato_usuario
     WHERE contrato_id = v_contrato_id
       AND usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     -- usuario ainda nao esta enderecado.
     INSERT INTO contrato_usuario
      (contrato_id,
       usuario_id,
       flag_responsavel)
     VALUES
      (v_contrato_id,
       v_usuario_id,
       v_flag_responsavel);
     --
     historico_pkg.hist_ender_registrar(v_usuario_id,
                                        'CTR',
                                        v_contrato_id,
                                        NULL,
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     /*
     -- verifica se esse usuario pode ser resp interno e marca
     resp_int_tratar(v_contrato_id, v_usuario_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000' THEN
        RAISE v_exception;
     END IF;
     */
    ELSE
     UPDATE contrato_usuario
        SET flag_responsavel = v_flag_responsavel
      WHERE contrato_id = v_contrato_id
        AND usuario_id = v_usuario_id;

    END IF;
    --
    -- verifica unidade de negocio do usuario responsavel
    IF v_flag_responsavel = 'S' THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM unidade_negocio_usu uu,
            unidade_negocio     un
      WHERE uu.usuario_id = v_usuario_id
        AND uu.unidade_negocio_id = un.unidade_negocio_id
        AND un.empresa_id = p_empresa_id;
     --
     IF v_qt > 0 THEN
      -- usuario pertence a apenas uma unidade de negocio na empresa
      -- do contrato.
      SELECT MAX(un.unidade_negocio_id)
        INTO v_unidade_negocio_id
        FROM unidade_negocio_usu uu,
             unidade_negocio     un
       WHERE uu.usuario_id = v_usuario_id
         AND uu.unidade_negocio_id = un.unidade_negocio_id
         AND un.empresa_id = p_empresa_id;
      --
      -- verifica se o cliente do contrato ja esta nessa UN
      SELECT COUNT(*)
        INTO v_qt
        FROM unidade_negocio_cli
       WHERE unidade_negocio_id = v_unidade_negocio_id
         AND cliente_id = v_contratante_id;
      --
      IF v_qt = 0 THEN
       INSERT INTO unidade_negocio_cli
        (unidade_negocio_id,
         cliente_id)
       VALUES
        (v_unidade_negocio_id,
         v_contratante_id);

      END IF;

     END IF;

    END IF; -- fim do IF v_flag_responsavel = 'S'
   END IF; -- fim do IF v_empresa_id = p_empresa_id
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_usuario
   WHERE contrato_id = v_contrato_id
     AND flag_responsavel = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Responsável não foi indicado.';
   RAISE v_exception;
  ELSIF v_qt > 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mais de um Responsável foi indicado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  contrato_pkg.enderecar_automatico(p_usuario_sessao_id,
                                    p_empresa_id,
                                    v_contrato_id,
                                    p_erro_cod,
                                    p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_contrato_id,
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
  -- geracao de evento - notificacao de contrato fisico
  ------------------------------------------------------------
  IF p_flag_ctr_fisico = 'S' THEN
   v_identif_objeto := to_char(v_numero_contrato);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'CONTRATO',
                    'NOTIFICAR2',
                    v_identif_objeto,
                    v_contrato_id,
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
  END IF;
  --
  p_contrato_id := v_contrato_id;
  p_erro_cod    := '00000';
  p_erro_msg    := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de contrato já existe (' || v_numero_contrato ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END adicionar_simples;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/09/2014
  -- DESCRICAO: Atualizacao de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Henrique          16/08/2019  Novo parametro p_tipo_mensal_vigencia (Mensal/Vigência)
  -- Silvia            15/10/2019  Retirada do parceiro_id
  -- Silvia            20/02/2020  Novo parametro p_tipo_contrato_id
  -- Silvia            30/11/2020  Tratamento das estimativas ao se alterar o periodo
  -- Silvia            18/01/2021  Retirada de tipo_mensal_vigencia
  -- Silvia            05/04/2021  Novo parametro flag_ctr_fisico
  -- Silvia            27/06/2023  Chamada de integracao de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_id            IN contrato.contrato_id%TYPE,
  p_tipo_contrato_id       IN contrato.tipo_contrato_id%TYPE,
  p_cod_ext_contrato       IN contrato.cod_ext_contrato%TYPE,
  p_nome                   IN contrato.nome%TYPE,
  p_contratante_id         IN contrato.contratante_id%TYPE,
  p_contato_id             IN contrato.contato_id%TYPE,
  p_emp_resp_id            IN contrato.emp_resp_id%TYPE,
  p_data_assinatura        IN VARCHAR2,
  p_data_inicio            IN VARCHAR2,
  p_data_termino           IN VARCHAR2,
  p_flag_repetir           IN VARCHAR2,
  p_flag_renovavel         IN VARCHAR2,
  p_flag_ctr_fisico        IN VARCHAR2,
  p_objeto                 IN contrato.objeto%TYPE,
  p_ordem_compra           IN contrato.ordem_compra%TYPE,
  p_cod_ext_ordem          IN contrato.cod_ext_ordem%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_contato_fatur_id       IN contrato.contato_fatur_id%TYPE,
  p_flag_pago_cliente      IN VARCHAR2,
  p_flag_bloq_negoc        IN VARCHAR2,
  p_flag_bv_fornec         IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_emp_faturar_por_id     IN contrato.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS

  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_numero_contrato        contrato.numero%TYPE;
  v_perc_bv                contrato.perc_bv%TYPE;
  v_data_assinatura        contrato.data_assinatura%TYPE;
  v_data_assinatura_old    contrato.data_assinatura%TYPE;
  v_data_inicio            contrato.data_inicio%TYPE;
  v_data_termino           contrato.data_termino%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_natureza_item_id VARCHAR2(1000);
  v_vetor_valor_padrao     VARCHAR2(1000);
  v_natureza_item_id       contrato_nitem_pdr.natureza_item_id%TYPE;
  v_valor_padrao           contrato_nitem_pdr.valor_padrao%TYPE;
  v_valor_padrao_char      VARCHAR2(50);
  v_nome_natureza          natureza_item.nome%TYPE;
  v_mod_calculo            natureza_item.mod_calculo%TYPE;
  v_desc_calculo           VARCHAR2(100);
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  v_flag_usar_servico      VARCHAR2(10);
  --
 BEGIN
  v_qt                := 0;
  v_flag_usar_servico := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_CONTRATO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
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
  SELECT numero,
         data_assinatura
    INTO v_numero_contrato,
         v_data_assinatura_old
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_contrato_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contratante_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contratante é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_contratante_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contratante não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao r
    WHERE r.pessoa_pai_id = p_contratante_id
      AND r.pessoa_filho_id = p_contato_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato não está associado a esse contratante.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF v_flag_usar_servico = 'N' THEN
   IF nvl(p_emp_resp_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_resp_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável não existe.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF data_validar(p_data_assinatura) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de assinatura inválida (' || p_data_assinatura || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do início da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da vigência inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_assinatura := data_converter(p_data_assinatura);
  v_data_inicio     := data_converter(p_data_inicio);
  v_data_termino    := data_converter(p_data_termino);
  --
  IF flag_validar(p_flag_renovavel) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag renovável inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ctr_fisico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag contrato físico inválido.';
   RAISE v_exception;
  END IF; --
  IF numero_validar(p_perc_bv) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv := numero_converter(p_perc_bv);
  --
  IF nvl(p_contato_fatur_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao r
    WHERE r.pessoa_pai_id = p_contratante_id
      AND r.pessoa_filho_id = p_contato_fatur_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato de faturamento não está associado a esse contratante.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF flag_validar(p_flag_pago_cliente) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pago pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bloq_negoc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag bloquear negociação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bv_fornec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag BV fornecedor inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_bv_fornec = 'S' AND nvl(v_perc_bv, 0) <> 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ao se utilizar o BV padrão de cada fornecedor, ' ||
                 'o percentual de BV não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET contratante_id     = p_contratante_id,
         contato_id         = zvl(p_contato_id, NULL),
         tipo_contrato_id   = p_tipo_contrato_id,
         emp_resp_id        = zvl(p_emp_resp_id, NULL),
         nome               = TRIM(p_nome),
         cod_ext_contrato   = TRIM(p_cod_ext_contrato),
         objeto             = p_objeto,
         flag_renovavel     = p_flag_renovavel,
         flag_ctr_fisico    = p_flag_ctr_fisico,
         perc_bv            = v_perc_bv,
         flag_bv_fornec     = p_flag_bv_fornec,
         flag_pago_cliente  = p_flag_pago_cliente,
         flag_bloq_negoc    = p_flag_bloq_negoc,
         ordem_compra       = TRIM(p_ordem_compra),
         cod_ext_ordem      = TRIM(p_cod_ext_ordem),
         contato_fatur_id   = zvl(p_contato_fatur_id, NULL),
         emp_faturar_por_id = zvl(p_emp_faturar_por_id, NULL)
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de naturezas do item
  ------------------------------------------------------------
  DELETE FROM contrato_nitem_pdr
   WHERE contrato_id = p_contrato_id;
  --
  v_delimitador            := '|';
  v_vetor_natureza_item_id := rtrim(p_vetor_natureza_item_id);
  v_vetor_valor_padrao     := rtrim(p_vetor_valor_padrao);
  --
  WHILE nvl(length(rtrim(v_vetor_natureza_item_id)), 0) > 0
  LOOP
   v_natureza_item_id  := nvl(to_number(prox_valor_retornar(v_vetor_natureza_item_id, v_delimitador)),
                              0);
   v_valor_padrao_char := prox_valor_retornar(v_vetor_valor_padrao, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa (' ||
                  to_char(v_natureza_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          util_pkg.desc_retornar('mod_calculo', mod_calculo),
          mod_calculo
     INTO v_nome_natureza,
          v_desc_calculo,
          v_mod_calculo
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id;
   --
   IF v_mod_calculo = 'NA' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não se aplica para cálculos (' || v_nome_natureza || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_valor_padrao_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' ||
                  v_valor_padrao_char || ').';

    RAISE v_exception;
   END IF;
   --
   v_valor_padrao := numero_converter(v_valor_padrao_char);
   --
   IF v_valor_padrao IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do ' || v_desc_calculo || ' para ' || v_nome_natureza ||
                  ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO contrato_nitem_pdr
    (contrato_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (p_contrato_id,
     v_natureza_item_id,
     v_valor_padrao);

  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento da vigencia e estimativas de horas
  ------------------------------------------------------------
  contrato_pkg.atualizar_vigencia(p_usuario_sessao_id,
                                  p_empresa_id,
                                  'N',
                                  p_contrato_id,
                                  p_data_inicio,
                                  p_data_termino,
                                  p_flag_repetir,
                                  p_erro_cod,
                                  p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CONTRATO_ATUALIZAR',
                           p_empresa_id,
                           p_contrato_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
  -- trata assinatura do contrato
  ------------------------------------------------------------
  IF v_data_assinatura_old IS NOT NULL AND v_data_assinatura IS NULL THEN
   contrato_pkg.assinado_desmarcar(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   p_contrato_id,
                                   p_erro_cod,
                                   p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_data_assinatura_old IS NULL AND v_data_assinatura IS NOT NULL THEN
   contrato_pkg.assinado_marcar(p_usuario_sessao_id,
                                'N',
                                p_empresa_id,
                                p_contrato_id,
                                p_data_assinatura,
                                p_erro_cod,
                                p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
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
 END atualizar;
 --
 --
 PROCEDURE atualizar_vigencia
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/12/2020
  -- DESCRICAO: Atualizacao de vigencia do CONTRATO com Tratamento das estimativas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/06/2022  Tratamento de contrato_horas_usu
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_flag_repetir      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_numero_contrato  contrato.numero%TYPE;
  v_data_inicio      contrato.data_inicio%TYPE;
  v_data_termino     contrato.data_termino%TYPE;
  v_data_inicio_old  contrato.data_inicio%TYPE;
  v_data_termino_old contrato.data_termino%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  v_meses_old        NUMBER(5);
  v_meses_atu        NUMBER(5);
  v_mes_inicio_old   DATE;
  v_mes_termino_old  DATE;
  v_mes_inicio_atu   DATE;
  v_mes_termino_atu  DATE;
  v_dif              NUMBER(5);
  v_data             DATE;
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
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_A', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
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
  SELECT numero,
         data_inicio,
         data_termino
    INTO v_numero_contrato,
         v_data_inicio_old,
         v_data_termino_old
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do início da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da vigência inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término da vigência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da vigência inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_inicio  := data_converter(p_data_inicio);
  v_data_termino := data_converter(p_data_termino);
  --
  IF flag_validar(p_flag_repetir) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag repetir inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  IF p_flag_commit = 'S' THEN
   contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET data_inicio  = v_data_inicio,
         data_termino = v_data_termino
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- tratamento das estimativas de horas
  ------------------------------------------------------------
  v_mes_inicio_old  := data_converter('01/' || to_char(v_data_inicio_old, 'MM/YYYY'));
  v_mes_termino_old := data_converter('01/' || to_char(v_data_termino_old, 'MM/YYYY'));
  --
  v_mes_inicio_atu  := data_converter('01/' || to_char(v_data_inicio, 'MM/YYYY'));
  v_mes_termino_atu := data_converter('01/' || to_char(v_data_termino, 'MM/YYYY'));
  --
  -- verifica se o periodo em meses do contrato mudou
  IF v_mes_inicio_atu <> v_mes_inicio_old OR v_mes_termino_atu <> v_mes_termino_old THEN
   --
   v_meses_old := months_between(v_mes_termino_old, v_mes_inicio_old) + 1;
   v_meses_atu := months_between(v_mes_termino_atu, v_mes_inicio_atu) + 1;
   --
   IF v_meses_old = v_meses_atu THEN
    -- mudou o periodo mas a qtd de meses se manteve.
    -- apenas desloca as estimativas para os novos meses
    v_dif := months_between(v_mes_inicio_atu, v_mes_inicio_old);
    --
    UPDATE contrato_horas
       SET data = add_months(data, v_dif)
     WHERE contrato_id = p_contrato_id;

   ELSIF v_mes_termino_atu < v_mes_termino_old THEN
    -- elimina as estiamtias que ultrapassam a nova dada de termino
    DELETE FROM contrato_horas_usu hu
     WHERE EXISTS (SELECT 1
              FROM contrato_horas ch
             WHERE ch.contrato_id = p_contrato_id
               AND ch.data > v_mes_termino_atu
               AND ch.contrato_horas_id = hu.contrato_horas_id);

    DELETE FROM contrato_horas
     WHERE contrato_id = p_contrato_id
       AND data > v_mes_termino_atu;

   ELSIF v_mes_inicio_atu > v_mes_inicio_old THEN
    -- elimina as estimativas anteriores a nova data de inicio
    DELETE FROM contrato_horas_usu hu
     WHERE EXISTS (SELECT 1
              FROM contrato_horas ch
             WHERE ch.contrato_id = p_contrato_id
               AND data < v_mes_inicio_atu
               AND ch.contrato_horas_id = hu.contrato_horas_id);

    DELETE FROM contrato_horas
     WHERE contrato_id = p_contrato_id
       AND data < v_mes_inicio_atu;

   ELSIF v_mes_inicio_old = v_mes_inicio_atu AND v_mes_termino_old < v_mes_termino_atu AND
         p_flag_repetir = 'S' THEN
    -- contrato prorrogado. Copia a ultima estimativa para
    -- os meses subsequentes
    v_data := add_months(v_mes_termino_old, 1);
    WHILE v_data <= v_mes_termino_atu
    LOOP
     INSERT INTO contrato_horas
      (contrato_horas_id,
       contrato_id,
       contrato_servico_id,
       data,
       usuario_id,
       cargo_id,
       area_id,
       nivel,
       descricao,
       horas_planej,
       venda_hora_rev,
       venda_hora_pdr,
       custo_hora_pdr,
       venda_fator_ajuste)
      SELECT seq_contrato_horas.nextval,
             contrato_id,
             contrato_servico_id,
             v_data,
             usuario_id,
             cargo_id,
             area_id,
             nivel,
             descricao,
             horas_planej,
             venda_hora_rev,
             venda_hora_pdr,
             custo_hora_pdr,
             venda_fator_ajuste
        FROM contrato_horas
       WHERE contrato_id = p_contrato_id
         AND data = v_mes_termino_old;

     v_data := add_months(v_data, 1);
    END LOOP;

   END IF;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  IF p_flag_commit = 'S' THEN
   contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF p_flag_commit = 'S' THEN
   v_identif_objeto := to_char(v_numero_contrato);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'CONTRATO',
                    'ALTERAR',
                    v_identif_objeto,
                    p_contrato_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    v_xml_antes,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
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
 END atualizar_vigencia;
 --
 --
 PROCEDURE atualizar_responsavel
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/05/2020
  -- DESCRICAO: define o responsavel interno pelo contrato (apenas 1). Quando
  --  usuario_id = 0, desmarca todos os responsaveis internos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_justif_histor   historico.justificativa%TYPE;
  v_apelido         pessoa.apelido%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero)
    INTO v_numero_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_usuario
     SET flag_responsavel = 'N'
   WHERE contrato_id = p_contrato_id;
  --
  IF nvl(p_usuario_id, 0) > 0 THEN
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'CONTRATO_RESP_INT_V', NULL, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário ' || v_apelido || ' não tem privilégio para ser responsável.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_usuario
    WHERE contrato_id = p_contrato_id
      AND usuario_id = p_usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO contrato_usuario
     (contrato_id,
      usuario_id,
      flag_responsavel)
    VALUES
     (p_contrato_id,
      p_usuario_id,
      'S');

   ELSE
    UPDATE contrato_usuario
       SET flag_responsavel = 'S'
     WHERE contrato_id = p_contrato_id
       AND usuario_id = p_usuario_id;

   END IF;
   --
   historico_pkg.hist_ender_registrar(p_usuario_id,
                                      'CTR',
                                      p_contrato_id,
                                      NULL,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF; -- fim do IF NVL(p_usuario_id,0) > 0
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração de responsável: ' || nvl(v_apelido, 'ND');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 PROCEDURE desconto_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/06/2016
  -- DESCRICAO: Atualizacao de desconto de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_perc_desc         IN VARCHAR2,
  p_motivo_desc       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_contrato contrato.numero%TYPE;
  v_perc_desc       contrato.perc_desc%TYPE;
  v_perc_desc_old   contrato.perc_desc%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_A', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
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
  SELECT numero,
         perc_desc
    INTO v_numero_contrato,
         v_perc_desc_old
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF numero_validar(p_perc_desc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de desconto inválido (' || p_perc_desc || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_desc := nvl(numero_converter(p_perc_desc), 0);
  --
  IF v_perc_desc < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de desconto inválido (' || p_perc_desc || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_perc_desc > 0 AND TRIM(p_motivo_desc) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo do desconto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_desc) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo do desconto não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_perc_desc = 0 THEN
   UPDATE contrato
      SET perc_desc       = 0,
          motivo_desc     = NULL,
          data_desc       = NULL,
          usuario_desc_id = NULL
    WHERE contrato_id = p_contrato_id;

  ELSE
   UPDATE contrato
      SET perc_desc       = v_perc_desc,
          motivo_desc     = TRIM(p_motivo_desc),
          data_desc       = SYSDATE,
          usuario_desc_id = p_usuario_sessao_id
    WHERE contrato_id = p_contrato_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração de desconto (' || taxa_mostrar(v_perc_desc) || '%)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END desconto_atualizar;
 --
 --
 PROCEDURE assinado_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 27/06/2016
  -- DESCRICAO: Marca um contrato como assinado..
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_assinatura   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_contrato contrato.numero%TYPE;
  v_status          contrato.status%TYPE;
  v_data_assinatura contrato.data_assinatura%TYPE;
  v_desc_status     VARCHAR(100);
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
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
  SELECT numero,
         status,
         util_pkg.desc_retornar('status_contrato', status)
    INTO v_numero_contrato,
         v_status,
         v_desc_status
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data_assinatura) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de assinatura é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_assinatura) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de assinatura inválida (' || p_data_assinatura || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_assinatura := data_converter(p_data_assinatura);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET data_assinatura = v_data_assinatura,
         flag_assinado   = 'S'
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Status: ' || v_desc_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ASSINAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END assinado_marcar;
 --
 --
 PROCEDURE assinado_desmarcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 27/06/2016
  -- DESCRICAO: Marca um contrato como NAO assinado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_contrato contrato.numero%TYPE;
  v_status          contrato.status%TYPE;
  v_data_assinatura contrato.data_assinatura%TYPE;
  v_desc_status     VARCHAR(100);
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
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
  SELECT numero,
         status,
         util_pkg.desc_retornar('status_contrato', status)
    INTO v_numero_contrato,
         v_status,
         v_desc_status
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET data_assinatura = NULL,
         flag_assinado   = 'N'
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Status: ' || v_desc_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'DESASSINAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END assinado_desmarcar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/09/2014
  -- DESCRICAO: Exclusão de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/09/2016  Exclusao automatica de contrato_nitem_pdr.
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Silvia            23/02/2021  Consistencia de servicos
  -- Silvia            20/01/2022  Consistencia de apontam_hora
  -- Silvia            21/06/2022  Exclusao automatica de contrato_elab
  -- Silvia            21/06/2022  Exclusao automatica de contrato_horas_usu
  -- Silvia            27/06/2023  Chamada de integracao de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_lbl_jobs        VARCHAR2(100);
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
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
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_E',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato = 'CONC' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite a exclusão.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE contrato_id = p_contrato_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse contrato.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE contrato_id = p_contrato_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Parcelas associadas a esse contrato.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_servico
   WHERE contrato_id = p_contrato_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem produtos associados a esse contrato.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_contrato
   WHERE contrato_id = p_contrato_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a esse contrato.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE contrato_id = p_contrato_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de hora associados a esse contrato.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CONTRATO_EXCLUIR',
                           p_empresa_id,
                           p_contrato_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  DELETE FROM contrato_horas_usu cs
   WHERE EXISTS (SELECT 1
            FROM contrato_horas ch
           WHERE ch.contrato_id = p_contrato_id
             AND ch.contrato_horas_id = cs.contrato_horas_id);

  DELETE FROM contrato_horas
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_usuario
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_nitem_pdr
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_elab
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_contrato_id,
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
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/09/2014
  -- DESCRICAO: apaga completamente um determinado CONTRATO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/09/2016  Exclusao de contrato_nitem_pdr.
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Silvia            23/02/2021  Exclusao de contrato_servico
  -- Silvia            27/06/2022  Exclusao de contrato_horas_usu, contrato_elab
  -- Silvia            27/06/2022  Exclusao de contrato_elab
  -- Silvia            27/06/2023  Chamada de integracao de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
  CURSOR c_arq_ct IS
   SELECT arquivo_id
     FROM arquivo_contrato
    WHERE contrato_id = p_contrato_id;
  --
  CURSOR c_arq_fi IS
   SELECT ac.arquivo_id
     FROM arquivo_contrato_fisico ac,
          contrato_fisico         cf
    WHERE cf.contrato_id = p_contrato_id
      AND cf.contrato_fisico_id = ac.contrato_fisico_id;
  --
 BEGIN
  v_qt := 0;
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
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_X',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CONTRATO_EXCLUIR',
                           p_empresa_id,
                           p_contrato_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  FOR r_arq_ct IN c_arq_ct
  LOOP
   DELETE FROM arquivo_contrato
    WHERE arquivo_id = r_arq_ct.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ct.arquivo_id;

  END LOOP;
  --
  FOR r_arq_fi IN c_arq_fi
  LOOP
   DELETE FROM arquivo_contrato_fisico
    WHERE arquivo_id = r_arq_fi.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_fi.arquivo_id;

  END LOOP;
  --
  UPDATE job
     SET contrato_id = NULL
   WHERE contrato_id = p_contrato_id;
  --
  DELETE FROM oport_contrato
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_horas_usu cs
   WHERE EXISTS (SELECT 1
            FROM contrato_horas ch
           WHERE ch.contrato_id = p_contrato_id
             AND ch.contrato_horas_id = cs.contrato_horas_id);

  DELETE FROM contrato_horas
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_item
   WHERE contrato_id = p_contrato_id;

  DELETE FROM abatimento_ctr ab
   WHERE EXISTS (SELECT 1
            FROM parcela_contrato pa
           WHERE pa.contrato_id = p_contrato_id
             AND pa.parcela_contrato_id = ab.parcela_contrato_id);

  DELETE FROM contrato_usuario
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_nitem_pdr
   WHERE contrato_id = p_contrato_id;

  DELETE FROM parcela_fatur_ctr pf
   WHERE EXISTS (SELECT 1
            FROM faturamento_ctr fa
           WHERE fa.contrato_id = p_contrato_id
             AND fa.faturamento_ctr_id = pf.faturamento_ctr_id);

  DELETE FROM parcela_contrato
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_serv_valor cv
   WHERE EXISTS (SELECT 1
            FROM contrato_servico cs
           WHERE cs.contrato_id = p_contrato_id
             AND cs.contrato_servico_id = cv.contrato_servico_id);

  DELETE FROM contrato_servico
   WHERE contrato_id = p_contrato_id;

  DELETE FROM faturamento_ctr
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_elab
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato_fisico
   WHERE contrato_id = p_contrato_id;

  DELETE FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'APAGAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 PROCEDURE concluir_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 01/09/2021
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a concluir
  --     automaticamente contratos, caso o parametro esteja ligado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/12/2021  Tratamento do parametro igual a zero.
  -- Silvia            16/09/2022  Alteracao da logica no uso do parametro NUM_DIAS_CONC_CTR
  --                               para selecionar apenas os contratos cuja data de termino
  --                               mais esse nro de dias BATA com a data de hoje.
  ------------------------------------------------------------------------------------------
  IS

  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_erro_cod          VARCHAR2(20);
  v_erro_msg          VARCHAR2(200);
  v_num_dias_conc_ctr NUMBER(10);
  v_empresa_id        empresa.empresa_id%TYPE;
  v_contrato_id       contrato.contrato_id%TYPE;
  v_usuario_admin_id  usuario.usuario_id%TYPE;
  v_complemento       VARCHAR2(100);
  --
  CURSOR c_em IS
   SELECT empresa_id
     FROM empresa
    WHERE flag_ativo = 'S'
    ORDER BY empresa_id;
  --
  -- Contratos a concluir
  CURSOR c_ct IS
   SELECT contrato_id
     FROM contrato
    WHERE empresa_id = v_empresa_id
      AND status NOT IN ('CONC', 'CANC')
      AND trunc(data_termino) + v_num_dias_conc_ctr = trunc(SYSDATE)
    ORDER BY contrato_id;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_admin_id IS NULL THEN
   v_erro_cod := '90000';
   v_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  v_complemento := '- concluído automaticamente devido ao término da vigência';
  --
  FOR r_em IN c_em
  LOOP
   v_empresa_id        := r_em.empresa_id;
   v_num_dias_conc_ctr := nvl(empresa_pkg.parametro_retornar(v_empresa_id, 'NUM_DIAS_CONC_CTR'), 0);
   --
   IF v_num_dias_conc_ctr > 0 THEN
    FOR r_ct IN c_ct
    LOOP
     v_contrato_id := r_ct.contrato_id;
     --
     contrato_pkg.status_alterar(v_usuario_admin_id,
                                 v_empresa_id,
                                 'N',
                                 v_contrato_id,
                                 'CONC',
                                 v_complemento,
                                 v_erro_cod,
                                 v_erro_msg);

     COMMIT;
    END LOOP;
   END IF;

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
     'ordem_servico_pkg.concluir_automatico',
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
     'ordem_servico_pkg.concluir_automatico',
     v_erro_cod,
     v_erro_msg);

   COMMIT;
 END concluir_automatico;
 --
 --
 PROCEDURE enderecar_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/08/2019
  -- DESCRICAO: subrotina p/ Enderecamento automatico do CONTRATO.
  --            NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt             INTEGER;
  v_exception      EXCEPTION;
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
      AND pr2.codigo = 'CONTRATO_I'
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
    WHERE pa.flag_auto_ender_ctr = 'S'
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
     FROM contrato_usuario
    WHERE contrato_id = p_contrato_id
      AND usuario_id = r_usu.usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO contrato_usuario
     (contrato_id,
      usuario_id)
    VALUES
     (p_contrato_id,
      r_usu.usuario_id);
    --
    -- verifica se esse usuario pode ser resp interno e marca
    resp_int_tratar(p_contrato_id, r_usu.usuario_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    historico_pkg.hist_ender_registrar(r_usu.usuario_id,
                                       'CTR',
                                       p_contrato_id,
                                       NULL,
                                       p_erro_cod,
                                       p_erro_msg);

    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
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
 PROCEDURE enderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/08/2022
  -- DESCRICAO: subrotina p/ Enderecamento de 1 usuario ao CONTRATO.
  --            NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_usuario_id        IN contrato_usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_usuario
   WHERE contrato_id = p_contrato_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   INSERT INTO contrato_usuario
    (contrato_id,
     usuario_id)
   VALUES
    (p_contrato_id,
     p_usuario_id);
   --
   -- verifica se esse usuario pode ser resp interno e marca
   resp_int_tratar(p_contrato_id, p_usuario_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   historico_pkg.hist_ender_registrar(p_usuario_id,
                                      'CTR',
                                      p_contrato_id,
                                      NULL,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
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

 END enderecar_usuario;
 --
 --
 PROCEDURE enderecar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/09/2014
  -- DESCRICAO: Enderecamento de usuarios do CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao do papel no enderecamento
  -- Ana Luiza         31/10/2023  Alteracao do privilegio e adicao area_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_vetor_usuarios  VARCHAR2(500);
  v_delimitador     CHAR(1);
  v_usuario_id      usuario.usuario_id%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe (' || to_char(p_contrato_id) || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  --ALCBO_311023
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_ENDER_AREA',
                                p_contrato_id,
                                p_area_id,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A área não foi informada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- limpa os enderecamentos da area
  DELETE FROM contrato_usuario ct
   WHERE ct.contrato_id = p_contrato_id
     AND EXISTS (SELECT 1
            FROM usuario us
           WHERE us.area_id = p_area_id
             AND us.usuario_id = ct.usuario_id);
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
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_usuario
    WHERE contrato_id = p_contrato_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    -- usuario ainda nao esta enderecado.
    INSERT INTO contrato_usuario
     (contrato_id,
      usuario_id)
    VALUES
     (p_contrato_id,
      v_usuario_id);
    --
    historico_pkg.hist_ender_registrar(v_usuario_id,
                                       'CTR',
                                       p_contrato_id,
                                       NULL,
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- verifica se esse usuario pode ser resp interno e marca
   resp_int_tratar(p_contrato_id, v_usuario_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração de endereçamento';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END enderecar;
 --
 --
 PROCEDURE status_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 08/09/2014
  -- DESCRICAO: Alteracao do status de um determinado contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/08/2021  Novos parametros flag_commit e complemeno
  -- Silvia            27/06/2023  Chamada de integracao na aprovacao de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_status_new        IN contrato.status%TYPE,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_contrato contrato.numero%TYPE;
  v_status_old      contrato.status%TYPE;
  v_empresa_id      contrato.empresa_id%TYPE;
  v_desc_status_old VARCHAR(100);
  v_desc_status     VARCHAR(100);
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_cod_acao        tipo_acao.codigo%TYPE;
  v_xml_atual       CLOB;
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
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         util_pkg.desc_retornar('status_contrato', status),
         empresa_id
    INTO v_numero_contrato,
         v_status_old,
         v_desc_status_old,
         v_empresa_id
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF p_flag_commit = 'S' THEN
   -- soh testa privilegio qdo a chamada for via interface.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CONTRATO_A',
                                 p_contrato_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_status_new) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(descricao)
    INTO v_desc_status
    FROM dicionario
   WHERE tipo = 'status_contrato'
     AND codigo = p_status_new;
  --
  IF v_desc_status IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do status inválido (' || p_status_new || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_status_old = p_status_new THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato já se encontra nesse status.';
   RAISE v_exception;
  END IF;
  --
  IF p_status_new = 'PREP' AND v_status_old NOT IN ('ANDA', 'CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (de: ' || v_status_old || ' para: ' || p_status_new || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_status_new = 'CONC' AND v_status_old <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (de: ' || v_status_old || ' para: ' || p_status_new || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_status_new = 'CANC' AND v_status_old = 'CONC' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (de: ' || v_status_old || ' para: ' || p_status_new || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET status      = p_status_new,
         data_status = SYSDATE
   WHERE contrato_id = p_contrato_id;
  --
  IF v_status_old = 'PREP' AND p_status_new = 'ANDA' THEN
   v_cod_acao := 'APROVAR';
  ELSIF v_status_old = 'PREP' AND p_status_new = 'CANC' THEN
   v_cod_acao := 'CANCELAR';
  ELSIF v_status_old = 'ANDA' AND p_status_new = 'PREP' THEN
   v_cod_acao := 'REPROVAR';
  ELSIF v_status_old = 'ANDA' AND p_status_new = 'CONC' THEN
   v_cod_acao := 'CONCLUIR';
  ELSIF v_status_old = 'ANDA' AND p_status_new = 'CANC' THEN
   v_cod_acao := 'CANCELAR';
  ELSIF v_status_old = 'CONC' AND p_status_new = 'ANDA' THEN
   v_cod_acao := 'REABRIR';
  ELSIF v_status_old = 'CANC' AND p_status_new = 'PREP' THEN
   v_cod_acao := 'DESCANCELAR';
  ELSE
   -- transicao nao prevista.
   -- registra como alteracao para nao dar erro.
   v_cod_acao := 'ALTERAR';
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF v_cod_acao = 'APROVAR' THEN
   it_controle_pkg.integrar('CONTRATO_ADICIONAR',
                            p_empresa_id,
                            p_contrato_id,
                            NULL,
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
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Status alterado: ' || v_desc_status_old || ' para ' || v_desc_status;
  --
  IF TRIM(p_complemento) IS NOT NULL THEN
   v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
  END IF;
  --
  -- usa a empresa do contrato pois a proc pode ter sido chamada via reabertura
  -- de oportunidade de outra ampresa.
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_id,
                   'CONTRATO',
                   v_cod_acao,
                   v_identif_objeto,
                   p_contrato_id,
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
 END status_alterar;
 --
 --
 PROCEDURE horas_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/09/2014
  -- DESCRICAO: Inclusão de horas planejadas no contrato via vetor
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/03/2015  Novos parametros (usuario_id, venda_hora_rev)
  -- Silvia            23/03/2016  Fator de ajuste.
  -- Silvia            27/05/2016  Encriptacao de valores
  -- Silvia            23/09/2016  Novo tipo POR_CARGO
  -- Silvia            26/12/2017  Testa definicao de cargo do usuario.
  -- Silvia            02/01/2018  Guarda area_id.
  -- Silvia            17/06/2019  Novo campo descricao.
  -- Silvia            14/05/2020  Eliminacao do papel_id
  -- Silvia            04/11/2020  Horas passou a aceitar decimais
  -- Silvia            10/11/2020  Mudancas para implementacao do mes/ano (vetores)
  -- Silvia            22/12/2020  Tenta pegar a area do cargo ja instanciada na estimativa
  -- Silvia            12/05/2022  Novo parametro contrato_servico_id
  -- Ana Luiza         19/12/2023  Pego o ultimo salario_cargo_id do nivel e cargo_id ----
  --                               inseridos
  -- Ana Luiza         29/08/2024  Evitar problema 9999, adicionado rate card padrao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_id         IN contrato_horas.contrato_id%TYPE,
  p_tipo_formulario     IN VARCHAR2,
  p_usuario_id          IN contrato_horas.usuario_id%TYPE,
  p_cargo_id            IN contrato_horas.cargo_id%TYPE,
  p_nivel               IN contrato_horas.nivel%TYPE,
  p_contrato_servico_id IN contrato_horas.contrato_servico_id%TYPE,
  p_descricao           IN VARCHAR2,
  p_vetor_mes_ano_de    IN VARCHAR2,
  p_vetor_mes_ano_ate   IN VARCHAR2,
  p_vetor_horas_planej  IN VARCHAR2,
  p_vetor_venda_hora    IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_numero_contrato    contrato.numero%TYPE;
  v_status_contrato    contrato.status%TYPE;
  v_data_inicio        contrato.data_inicio%TYPE;
  v_data_termino       contrato.data_termino%TYPE;
  v_nome_area          area.nome%TYPE;
  v_nome_cargo         cargo.nome%TYPE;
  v_cargo_id           cargo.cargo_id%TYPE;
  v_contrato_horas_id  contrato_horas.contrato_horas_id%TYPE;
  v_horas_planej       contrato_horas.horas_planej%TYPE;
  v_venda_hora_rev     contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr     contrato_horas.venda_hora_pdr%TYPE;
  v_venda_hora_rev_en  contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr_en  contrato_horas.venda_hora_pdr%TYPE;
  v_custo_hora_pdr_en  contrato_horas.custo_hora_pdr%TYPE;
  v_venda_fator_ajuste contrato_horas.venda_fator_ajuste%TYPE;
  v_area_id            contrato_horas.area_id%TYPE;
  v_data               contrato_horas.data%TYPE;
  v_data_de            contrato_horas.data%TYPE;
  v_data_ate           contrato_horas.data%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_nome_usuario       pessoa.apelido%TYPE;
  v_salario_id         salario.salario_id%TYPE;
  v_salario_cargo_id   salario_cargo.salario_cargo_id%TYPE;
  v_vetor_mes_ano_de   VARCHAR2(4000);
  v_vetor_mes_ano_ate  VARCHAR2(4000);
  v_vetor_horas_planej VARCHAR2(4000);
  v_vetor_venda_hora   VARCHAR2(4000);
  v_mes_ano_de         VARCHAR2(20);
  v_mes_ano_ate        VARCHAR2(20);
  v_horas_planej_char  VARCHAR2(20);
  v_venda_hora_char    VARCHAR2(20);
  v_delimitador        CHAR(1);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --ALCBO_290824
  v_tab_preco_padrao tab_preco.preco_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status),
         MAX(data_inicio),
         MAX(data_termino)
    INTO v_numero_contrato,
         v_status_contrato,
         v_data_inicio,
         v_data_termino
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_formulario) IS NULL OR p_tipo_formulario NOT IN ('POR_USUARIO', 'POR_CARGO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de formulário inválido (' || p_tipo_formulario || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contrato_servico_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_servico
    WHERE contrato_id = p_contrato_id
      AND contrato_servico_id = p_contrato_servico_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe ou não pertence a esse contrato.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nivel) IS NOT NULL AND util_pkg.desc_retornar('nivel_usuario', p_nivel) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível inválido (' || p_nivel || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   IF nvl(p_usuario_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do usuário é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_cargo_id, 0) <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O cargo não deve ser informado.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   v_salario_id := salario_pkg.salario_id_atu_retornar(p_usuario_id);
   --
   SELECT MAX(custo_hora),
          MAX(venda_hora)
     INTO v_custo_hora_pdr_en,
          v_venda_hora_pdr_en
     FROM salario
    WHERE salario_id = v_salario_id;
   --
   -- o cargo eh usado apenas para pegar a area
   v_cargo_id := cargo_pkg.do_usuario_retornar(p_usuario_id, trunc(SYSDATE), p_empresa_id);
   --
   IF v_cargo_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O cargo não definido para o usuário ' || v_nome_usuario || '.';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          area_id
     INTO v_nome_cargo,
          v_area_id
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF; -- fim do IF p_tipo_formulario = 'POR_USUARIO'
  --
  IF p_tipo_formulario = 'POR_CARGO' THEN
   IF nvl(p_cargo_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do cargo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM cargo
    WHERE cargo_id = p_cargo_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = p_cargo_id;
   --
   IF nvl(p_usuario_id, 0) <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário não deve ser informado.';
    RAISE v_exception;
   END IF;
   --ALCBO_191223
   --v_salario_cargo_id := cargo_pkg.salario_id_atu_retornar(p_cargo_id,p_nivel);
   --ALCBO_290824
   v_salario_cargo_id := cargo_pkg.salario_id_atu_retornar(p_cargo_id, p_nivel);
   --
   SELECT MAX(custo_hora),
          MAX(venda_hora)
     INTO v_custo_hora_pdr_en,
          v_venda_hora_pdr_en
     FROM salario_cargo
    WHERE salario_cargo_id = v_salario_cargo_id;
   --
   -- tenta pegar area ja instanciada p/ o cargo/nivel
   SELECT MAX(area_id)
     INTO v_area_id
     FROM contrato_horas
    WHERE contrato_id = p_contrato_id
      AND cargo_id = p_cargo_id
      AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');
   --
   IF v_area_id IS NULL THEN
    SELECT area_id
      INTO v_area_id
      FROM cargo
     WHERE cargo_id = p_cargo_id;

   END IF;

  END IF; -- fim do IF p_tipo_formulario = 'POR_CARGO'
  --
  IF length(TRIM(p_descricao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- desencripta para poder calcular
  v_venda_hora_pdr := util_pkg.num_decode(v_venda_hora_pdr_en, g_key_num);
  --
  v_delimitador        := '|';
  v_vetor_mes_ano_de   := rtrim(p_vetor_mes_ano_de);
  v_vetor_mes_ano_ate  := rtrim(p_vetor_mes_ano_ate);
  v_vetor_horas_planej := rtrim(p_vetor_horas_planej);
  v_vetor_venda_hora   := rtrim(p_vetor_venda_hora);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_mes_ano_de)), 0) > 0
  LOOP
   v_mes_ano_de        := prox_valor_retornar(v_vetor_mes_ano_de, v_delimitador);
   v_mes_ano_ate       := prox_valor_retornar(v_vetor_mes_ano_ate, v_delimitador);
   v_horas_planej_char := prox_valor_retornar(v_vetor_horas_planej, v_delimitador);
   v_venda_hora_char   := prox_valor_retornar(v_vetor_venda_hora, v_delimitador);
   --
   v_venda_fator_ajuste := NULL;
   --
   IF TRIM(v_mes_ano_de) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do mês/ano é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar('01/' || v_mes_ano_de) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Mês/ano inválido (' || v_mes_ano_de || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_de := data_converter('01/' || v_mes_ano_de);
   --
   IF TRIM(v_mes_ano_ate) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do mês/ano é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar('01/' || v_mes_ano_ate) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Mês/ano inválido (' || v_mes_ano_ate || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_ate := data_converter('01/' || v_mes_ano_ate);
   --
   IF TRIM(v_horas_planej_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento das horas é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_horas_planej_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Horas inválidas (' || v_horas_planej_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas_planej := nvl(round(numero_converter(v_horas_planej_char), 2), 0);
   --
   IF v_horas_planej < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Horas inválidas (' || v_horas_planej_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_venda_hora_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do preço da hora é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_venda_hora_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço da hora inválido (' || v_venda_hora_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_venda_hora_rev := nvl(moeda_converter(v_venda_hora_char), 0);
   --
   IF v_venda_hora_rev < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço da hora inválido (' || v_venda_hora_char || ').';
    RAISE v_exception;
   END IF;
   --
   -- encripta para salvar
   v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
   --
   IF v_venda_hora_rev_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_venda_hora_pdr <> 0 THEN
    v_venda_fator_ajuste := round(v_venda_hora_rev / v_venda_hora_pdr, 2);
   END IF;
   --
   v_data := v_data_de;
   WHILE v_data <= v_data_ate
   LOOP
    v_contrato_horas_id := NULL;
    --
    IF to_number(to_char(v_data, 'YYYYMM')) NOT BETWEEN to_number(to_char(v_data_inicio, 'YYYYMM')) AND
       to_number(to_char(v_data_termino, 'YYYYMM')) THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse mês/ano não se encontra na vigência do contrato (' ||
                   TRIM(to_char(v_data, 'MM/YYYY')) || ').';

     RAISE v_exception;
    END IF;
    --
    IF p_tipo_formulario = 'POR_USUARIO' THEN
     SELECT MAX(contrato_horas_id)
       INTO v_contrato_horas_id
       FROM contrato_horas
      WHERE contrato_id = p_contrato_id
        AND usuario_id = p_usuario_id
        AND data = v_data
        AND nvl(contrato_servico_id, 0) = nvl(p_contrato_servico_id, 0);

    ELSIF p_tipo_formulario = 'POR_CARGO' THEN
     SELECT MAX(contrato_horas_id)
       INTO v_contrato_horas_id
       FROM contrato_horas
      WHERE contrato_id = p_contrato_id
        AND cargo_id = p_cargo_id
        AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-')
        AND data = v_data
        AND nvl(contrato_servico_id, 0) = nvl(p_contrato_servico_id, 0);

    END IF;
    --
    IF v_contrato_horas_id IS NULL THEN
     INSERT INTO contrato_horas
      (contrato_horas_id,
       contrato_id,
       data,
       usuario_id,
       cargo_id,
       area_id,
       contrato_servico_id,
       nivel,
       descricao,
       horas_planej,
       venda_hora_rev,
       venda_hora_pdr,
       custo_hora_pdr,
       venda_fator_ajuste)
     VALUES
      (seq_contrato_horas.nextval,
       p_contrato_id,
       v_data,
       zvl(p_usuario_id, NULL),
       zvl(p_cargo_id, NULL),
       v_area_id,
       zvl(p_contrato_servico_id, 0),
       TRIM(p_nivel),
       TRIM(p_descricao),
       v_horas_planej,
       v_venda_hora_rev_en,
       v_venda_hora_pdr_en,
       v_custo_hora_pdr_en,
       v_venda_fator_ajuste);

    ELSE
     UPDATE contrato_horas
        SET horas_planej       = v_horas_planej,
            venda_hora_rev     = v_venda_hora_rev_en,
            venda_hora_pdr     = v_venda_hora_pdr_en,
            custo_hora_pdr     = v_custo_hora_pdr_en,
            venda_fator_ajuste = v_venda_fator_ajuste,
            descricao          = TRIM(p_descricao)
      WHERE contrato_horas_id = v_contrato_horas_id;

    END IF;
    --
    v_data := add_months(v_data, 1);
   END LOOP; -- fim do loop por data
  END LOOP; -- fim do loop por vetor
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   v_compl_histor := 'Inclusão de estimativa de horas: ' || v_nome_usuario || ' / ' || v_nome_area;
  ELSIF p_tipo_formulario = 'POR_CARGO' THEN
   v_compl_histor := 'Inclusão de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(p_nivel), 'ND');
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END horas_adicionar;
 --
 --
 PROCEDURE horas_desc_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/11/2020
  -- DESCRICAO: Alteração da descricao de horas planejadas no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_nome_area       area.nome%TYPE;
  v_area_id         area.area_id%TYPE;
  v_usuario_id      contrato_horas.usuario_id%TYPE;
  v_nivel           contrato_horas.nivel%TYPE;
  v_data            contrato_horas.data%TYPE;
  v_nome_usuario    pessoa.apelido%TYPE;
  v_cargo_id        cargo.cargo_id%TYPE;
  v_nome_cargo      cargo.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.usuario_id,
         ch.nivel,
         ch.cargo_id,
         ch.area_id,
         ch.data
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id,
         v_nivel,
         v_cargo_id,
         v_area_id,
         v_data
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_descricao)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_usuario_id IS NOT NULL THEN
   UPDATE contrato_horas
      SET descricao = TRIM(p_descricao)
    WHERE contrato_id = v_contrato_id
      AND usuario_id = v_usuario_id;

  ELSE
   UPDATE contrato_horas
      SET descricao = TRIM(p_descricao)
    WHERE contrato_id = v_contrato_id
      AND cargo_id = v_cargo_id
      AND area_id = v_area_id
      AND nvl(nivel, 'ZZZ') = nvl(v_nivel, 'ZZZ');

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (descrição): ' || ' - ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (descrição): ' || ' - ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END horas_desc_atualizar;
 --
 --
 PROCEDURE horas_planej_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/11/2020
  -- DESCRICAO: Alteração de horas planejadas no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_venda_valor_total OUT NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                INTEGER;
  v_contrato_id       contrato.contrato_id%TYPE;
  v_numero_contrato   contrato.numero%TYPE;
  v_status_contrato   contrato.status%TYPE;
  v_nome_area         area.nome%TYPE;
  v_area_id           area.area_id%TYPE;
  v_usuario_id        contrato_horas.usuario_id%TYPE;
  v_horas_planej      contrato_horas.horas_planej%TYPE;
  v_venda_hora_rev    contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en contrato_horas.venda_hora_rev%TYPE;
  v_nivel             contrato_horas.nivel%TYPE;
  v_data              contrato_horas.data%TYPE;
  v_nome_usuario      pessoa.apelido%TYPE;
  v_cargo_id          cargo.cargo_id%TYPE;
  v_nome_cargo        cargo.nome%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt                := 0;
  p_venda_valor_total := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.usuario_id,
         ch.nivel,
         ch.venda_hora_rev,
         ch.cargo_id,
         ch.area_id,
         ch.data
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id,
         v_nivel,
         v_venda_hora_rev_en,
         v_cargo_id,
         v_area_id,
         v_data
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_horas_planej) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das horas é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_horas_planej) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas (' || p_horas_planej || ').';
   RAISE v_exception;
  END IF;
  --
  v_horas_planej := nvl(round(numero_converter(p_horas_planej), 2), 0);
  --
  IF v_horas_planej < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas (' || p_horas_planej || ').';
   RAISE v_exception;
  END IF;
  --
  -- desencripta para poder calcular
  v_venda_hora_rev := util_pkg.num_decode(v_venda_hora_rev_en, g_key_num);
  --
  p_venda_valor_total := nvl(round(v_horas_planej * v_venda_hora_rev, 2), 0);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_horas_planej > 0 THEN
   UPDATE contrato_horas
      SET horas_planej = v_horas_planej
    WHERE contrato_horas_id = p_contrato_horas_id;

  ELSE
   DELETE FROM contrato_horas_usu
    WHERE contrato_horas_id = p_contrato_horas_id;

   DELETE FROM contrato_horas
    WHERE contrato_horas_id = p_contrato_horas_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (horas planej): ' || to_char(v_data, 'MM/YYYY') ||
                     ' - ' || v_nome_cargo || ' / ' || nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (horas planej): ' || to_char(v_data, 'MM/YYYY') ||
                     ' - ' || v_nome_usuario || ' / ' || v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END horas_planej_atualizar;
 --
 --
 PROCEDURE horas_fator_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/11/2020
  -- DESCRICAO: Alteração do fator de venda de horas no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_horas_id  IN contrato_horas.contrato_horas_id%TYPE,
  p_venda_fator_ajuste IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                     INTEGER;
  v_contrato_id            contrato.contrato_id%TYPE;
  v_numero_contrato        contrato.numero%TYPE;
  v_status_contrato        contrato.status%TYPE;
  v_nome_area              area.nome%TYPE;
  v_area_id                area.area_id%TYPE;
  v_usuario_id             contrato_horas.usuario_id%TYPE;
  v_venda_hora_rev         contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en      contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr         contrato_horas.venda_hora_pdr%TYPE;
  v_venda_fator_ajuste     contrato_horas.venda_fator_ajuste%TYPE;
  v_venda_fator_ajuste_old contrato_horas.venda_fator_ajuste%TYPE;
  v_nivel                  contrato_horas.nivel%TYPE;
  v_data                   contrato_horas.data%TYPE;
  v_nome_usuario           pessoa.apelido%TYPE;
  v_cargo_id               cargo.cargo_id%TYPE;
  v_nome_cargo             cargo.nome%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_xml_atual              CLOB;
  --
  CURSOR c_ch IS
   SELECT contrato_horas_id,
          venda_hora_pdr,
          venda_fator_ajuste
     FROM contrato_horas
    WHERE contrato_id = v_contrato_id
      AND data >= v_data
      AND area_id = v_area_id
      AND nvl(usuario_id, 0) = nvl(v_usuario_id, 0)
      AND nvl(cargo_id, 0) = nvl(v_cargo_id, 0)
      AND nvl(nivel, 'Z') = nvl(v_nivel, 'Z')
    ORDER BY data;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.usuario_id,
         ch.nivel,
         ch.cargo_id,
         ch.area_id,
         ch.data,
         ch.venda_fator_ajuste
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id,
         v_nivel,
         v_cargo_id,
         v_area_id,
         v_data,
         v_venda_fator_ajuste_old
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF taxa_validar(p_venda_fator_ajuste) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_fator_ajuste := taxa_converter(TRIM(p_venda_fator_ajuste));
  --
  IF v_venda_fator_ajuste < 0 OR v_venda_fator_ajuste > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o valor mudou
  IF nvl(v_venda_fator_ajuste_old, 99999) = nvl(v_venda_fator_ajuste, 99999) THEN
   -- nao mudou. Pula o processamento
   RAISE v_saida;
  END IF;
  --
  IF v_venda_fator_ajuste IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ch IN c_ch
  LOOP
   -- desencripta para poder usar
   v_venda_hora_pdr := util_pkg.num_decode(r_ch.venda_hora_pdr, g_key_num);
   --
   -- aplica o fator de ajuste
   IF nvl(v_venda_hora_pdr, 0) <> 0 THEN
    v_venda_hora_rev := round(v_venda_hora_pdr * v_venda_fator_ajuste, 2);
    --
    -- encripta para salvar
    v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
    --
    IF v_venda_hora_rev_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE contrato_horas
       SET venda_hora_rev     = v_venda_hora_rev_en,
           venda_fator_ajuste = v_venda_fator_ajuste
     WHERE contrato_horas_id = r_ch.contrato_horas_id;

   END IF;

  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (fator): ' || ' - ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (fator): ' || ' - ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
   ROLLBACK;
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END horas_fator_atualizar;
 --
 --
 PROCEDURE horas_venda_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 09/11/2020
  -- DESCRICAO: Alteração o valor de venda de horas no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/12/2020  Qdo o preco eh alterado, o fator fica nulo.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_venda_hora_rev    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                    INTEGER;
  v_contrato_id           contrato.contrato_id%TYPE;
  v_numero_contrato       contrato.numero%TYPE;
  v_status_contrato       contrato.status%TYPE;
  v_nome_area             area.nome%TYPE;
  v_area_id               area.area_id%TYPE;
  v_usuario_id            contrato_horas.usuario_id%TYPE;
  v_venda_hora_rev        contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en     contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en_old contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr        contrato_horas.venda_hora_pdr%TYPE;
  v_venda_fator_ajuste    contrato_horas.venda_fator_ajuste%TYPE;
  v_nivel                 contrato_horas.nivel%TYPE;
  v_data                  contrato_horas.data%TYPE;
  v_nome_usuario          pessoa.apelido%TYPE;
  v_cargo_id              cargo.cargo_id%TYPE;
  v_nome_cargo            cargo.nome%TYPE;
  v_exception             EXCEPTION;
  v_saida                 EXCEPTION;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_xml_atual             CLOB;
  --
  CURSOR c_ch IS
   SELECT contrato_horas_id,
          venda_hora_pdr,
          venda_fator_ajuste
     FROM contrato_horas
    WHERE contrato_id = v_contrato_id
      AND data >= v_data
      AND area_id = v_area_id
      AND nvl(usuario_id, 0) = nvl(v_usuario_id, 0)
      AND nvl(cargo_id, 0) = nvl(v_cargo_id, 0)
      AND nvl(nivel, 'Z') = nvl(v_nivel, 'Z')
    ORDER BY data;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.usuario_id,
         ch.nivel,
         ch.cargo_id,
         ch.area_id,
         ch.data,
         ch.venda_hora_rev
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id,
         v_nivel,
         v_cargo_id,
         v_area_id,
         v_data,
         v_venda_hora_rev_en_old
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_venda_hora_rev) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço da hora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_hora_rev) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_rev := nvl(moeda_converter(p_venda_hora_rev), 0);
  --
  IF v_venda_hora_rev < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  -- encripta para salvar
  v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
  --
  IF v_venda_hora_rev_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o valor mudou
  IF v_venda_hora_rev_en_old = v_venda_hora_rev_en THEN
   -- nao mudou. Pula o processamento
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ch IN c_ch
  LOOP
   /* nao recalcula mais o fator de ajuste
   -- desencripta para poder usar
   v_venda_hora_pdr := util_pkg.num_decode(r_ch.venda_hora_pdr,g_key_num);
   -- recupera fator caso nao possa ser recalculado
   v_venda_fator_ajuste := r_ch.venda_fator_ajuste;
   --
   IF v_venda_hora_pdr <> 0 THEN
      v_venda_fator_ajuste := ROUND(v_venda_hora_rev / v_venda_hora_pdr,2);
   END IF;
   */
   --
   UPDATE contrato_horas
      SET venda_fator_ajuste = NULL,
          venda_hora_rev     = v_venda_hora_rev_en
    WHERE contrato_horas_id = r_ch.contrato_horas_id;

  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (valor venda): ' || ' - ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (valor venda): ' || ' - ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
   ROLLBACK;
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END horas_venda_atualizar;
 --
 --
 PROCEDURE horas_ajustar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/03/2016
  -- DESCRICAO: Aplica fator de ajuste no preco de venda das horas do contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/05/2016  Encriptacao de valores
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_id        IN contrato.contrato_id%TYPE,
  p_venda_fator_ajuste IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_numero_contrato    contrato.numero%TYPE;
  v_status_contrato    contrato.status%TYPE;
  v_venda_fator_ajuste contrato_horas.venda_fator_ajuste%TYPE;
  v_venda_hora_pdr     contrato_horas.venda_hora_pdr%TYPE;
  v_venda_hora_rev     contrato_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en  contrato_horas.venda_hora_rev%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
  CURSOR c_ch IS
   SELECT contrato_horas_id,
          venda_hora_pdr AS venda_hora_pdr_en
     FROM contrato_horas
    WHERE contrato_id = p_contrato_id;
  --
 BEGIN
  v_qt := 0;
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
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_venda_fator_ajuste) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fator de ajuste é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_venda_fator_ajuste) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_fator_ajuste := taxa_converter(TRIM(p_venda_fator_ajuste));
  --
  IF v_venda_fator_ajuste < 0 OR v_venda_fator_ajuste > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ch IN c_ch
  LOOP
   -- desencripta para poder usar
   v_venda_hora_pdr := util_pkg.num_decode(r_ch.venda_hora_pdr_en, g_key_num);
   --
   -- aplica o fator de ajuste
   IF nvl(v_venda_hora_pdr, 0) <> 0 THEN
    v_venda_hora_rev := round(v_venda_hora_pdr * v_venda_fator_ajuste, 2);
    --
    -- encripta para salvar
    v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
    --
    IF v_venda_hora_rev_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE contrato_horas
       SET venda_hora_rev     = v_venda_hora_rev_en,
           venda_fator_ajuste = v_venda_fator_ajuste
     WHERE contrato_horas_id = r_ch.contrato_horas_id;

   END IF;

  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Ajuste de preços com o fator: ' || taxa_mostrar(v_venda_fator_ajuste) || '.';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END horas_ajustar;
 --
 --
 PROCEDURE horas_servico_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/05/2022
  -- DESCRICAO: Atualizacao/troca do servico das horas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_horas_id   IN contrato_horas.contrato_horas_id%TYPE,
  p_contrato_servico_id IN contrato_horas.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt                      INTEGER;
  v_contrato_id             contrato.contrato_id%TYPE;
  v_numero_contrato         contrato.numero%TYPE;
  v_status_contrato         contrato.status%TYPE;
  v_nome_area               area.nome%TYPE;
  v_area_id                 area.area_id%TYPE;
  v_contrato_servico_old_id contrato_horas.contrato_servico_id%TYPE;
  v_nivel                   contrato_horas.nivel%TYPE;
  v_usuario_id              contrato_horas.usuario_id%TYPE;
  v_nome_usuario            pessoa.apelido%TYPE;
  v_cargo_id                cargo.cargo_id%TYPE;
  v_nome_cargo              cargo.nome%TYPE;
  v_exception               EXCEPTION;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.nivel,
         ch.usuario_id,
         ch.cargo_id,
         ch.area_id,
         ch.contrato_servico_id
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_nivel,
         v_usuario_id,
         v_cargo_id,
         v_area_id,
         v_contrato_servico_old_id
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contrato_servico_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do novo produto é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_horas
     SET contrato_servico_id = p_contrato_servico_id
   WHERE nvl(contrato_servico_id, 0) = nvl(v_contrato_servico_old_id, 0)
     AND nvl(cargo_id, 0) = nvl(v_cargo_id, 0)
     AND nvl(nivel, 'ND') = nvl(TRIM(v_nivel), 'ND')
     AND contrato_id = v_contrato_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (produto): ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estim horas (produto): ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END horas_servico_atualizar;
 --
 --
 PROCEDURE horas_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/09/2014
  -- DESCRICAO: Exclusao de horas planejadas no contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/09/2016  Novo tipo POR_CARGO
  -- Silvia            14/05/2020  Eliminacao do papel_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_nome_area       area.nome%TYPE;
  v_area_id         area.area_id%TYPE;
  v_nivel           contrato_horas.nivel%TYPE;
  v_usuario_id      contrato_horas.usuario_id%TYPE;
  v_nome_usuario    pessoa.apelido%TYPE;
  v_cargo_id        cargo.cargo_id%TYPE;
  v_nome_cargo      cargo.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.nivel,
         ch.usuario_id,
         ch.cargo_id,
         ch.area_id
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_nivel,
         v_usuario_id,
         v_cargo_id,
         v_area_id
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM contrato_horas_usu
   WHERE contrato_horas_id = p_contrato_horas_id;

  DELETE FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_usuario || ' / ' || v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END horas_excluir;
 --
 --
 PROCEDURE horas_linha_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 26/11/2014
  -- DESCRICAO: Exclusao da linha de horas planejadas no contrato (por usuario ou cargo)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/06/2022  Tratamento de contrato_horas_usu
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato_horas.contrato_id%TYPE,
  p_usuario_id        IN contrato_horas.usuario_id%TYPE,
  p_cargo_id          IN contrato_horas.cargo_id%TYPE,
  p_nivel             IN contrato_horas.nivel%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_nome_usuario    pessoa.apelido%TYPE;
  v_nome_cargo      cargo.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) > 0 AND nvl(p_cargo_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas o usuário ou o cargo devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) = 0 AND nvl(p_cargo_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário ou o cargo devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) > 0 THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = p_usuario_id;

  END IF;
  --
  IF nvl(p_cargo_id, 0) > 0 THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = p_cargo_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) > 0 THEN
   DELETE FROM contrato_horas_usu cs
    WHERE EXISTS (SELECT 1
             FROM contrato_horas ch
            WHERE ch.contrato_id = p_contrato_id
              AND ch.usuario_id = p_usuario_id
              AND ch.contrato_horas_id = cs.contrato_horas_id);

   DELETE FROM contrato_horas
    WHERE contrato_id = p_contrato_id
      AND usuario_id = p_usuario_id;

  ELSE
   DELETE FROM contrato_horas_usu cs
    WHERE EXISTS (SELECT 1
             FROM contrato_horas ch
            WHERE ch.contrato_id = p_contrato_id
              AND ch.cargo_id = p_cargo_id
              AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-')
              AND ch.contrato_horas_id = cs.contrato_horas_id);

   DELETE FROM contrato_horas
    WHERE contrato_id = p_contrato_id
      AND cargo_id = p_cargo_id
      AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF nvl(p_cargo_id, 0) > 0 THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(p_nivel), 'ND');
  ELSIF nvl(p_usuario_id, 0) > 0 THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_usuario;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END horas_linha_excluir;
 --
 --
 PROCEDURE horas_usu_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/06/2022
  -- DESCRICAO: Alocacao de horas no contrato para os usuarios
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN contrato.empresa_id%TYPE,
  p_contrato_id             IN contrato.contrato_id%TYPE,
  p_vetor_contrato_horas_id IN VARCHAR2,
  p_vetor_usuario_id        IN VARCHAR2,
  p_vetor_horas_aloc        IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS

  v_qt                      INTEGER;
  v_numero_contrato         contrato.numero%TYPE;
  v_status_contrato         contrato.status%TYPE;
  v_contrato_horas_usu_id   contrato_horas_usu.contrato_horas_usu_id%TYPE;
  v_contrato_horas_id       contrato_horas_usu.contrato_horas_id%TYPE;
  v_horas_aloc              contrato_horas_usu.horas_aloc%TYPE;
  v_usuario_id              contrato_horas_usu.usuario_id%TYPE;
  v_exception               EXCEPTION;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_contrato_horas_id VARCHAR2(4000);
  v_vetor_usuario_id        VARCHAR2(4000);
  v_vetor_horas_aloc        VARCHAR2(4000);
  v_horas_aloc_char         VARCHAR2(20);
  v_xml_atual               CLOB;
  --
 BEGIN
  v_qt := 0;
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
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_USU_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador             := '|';
  v_vetor_contrato_horas_id := rtrim(p_vetor_contrato_horas_id);
  v_vetor_usuario_id        := rtrim(p_vetor_usuario_id);
  v_vetor_horas_aloc        := rtrim(p_vetor_horas_aloc);
  --
  WHILE nvl(length(rtrim(v_vetor_contrato_horas_id)), 0) > 0
  LOOP
   v_contrato_horas_id := nvl(to_number(prox_valor_retornar(v_vetor_contrato_horas_id,
                                                            v_delimitador)),
                              0);
   v_usuario_id        := nvl(to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador)), 0);
   v_horas_aloc_char   := prox_valor_retornar(v_vetor_horas_aloc, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_horas
    WHERE contrato_horas_id = v_contrato_horas_id
      AND contrato_id = p_contrato_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Contrato/horas inválido (' || to_char(v_contrato_horas_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_horas_aloc_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Horas inválidas (' || v_horas_aloc_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas_aloc := nvl(round(numero_converter(v_horas_aloc_char), 2), 0);
   --
   IF v_horas_aloc < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Horas inválidas (' || v_horas_aloc_char || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_horas_usu
    WHERE contrato_horas_id = v_contrato_horas_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem usuários já alocados ou repetidos no vetor.';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_contrato_horas_usu.nextval
     INTO v_contrato_horas_usu_id
     FROM dual;
   --
   INSERT INTO contrato_horas_usu
    (contrato_horas_usu_id,
     contrato_horas_id,
     usuario_id,
     horas_aloc)
   VALUES
    (v_contrato_horas_usu_id,
     v_contrato_horas_id,
     v_usuario_id,
     v_horas_aloc);

  END LOOP; -- fim do loop por vetor
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Inclusão de horas alocadas';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END horas_usu_adicionar;
 --
 --
 PROCEDURE horas_usu_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/06/2022
  -- DESCRICAO: Atualizacao de Alocacao de horas no contrato para o usuario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN contrato.empresa_id%TYPE,
  p_contrato_horas_usu_id IN contrato_horas_usu.contrato_horas_usu_id%TYPE,
  p_horas_aloc            IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS

  v_qt                INTEGER;
  v_numero_contrato   contrato.numero%TYPE;
  v_status_contrato   contrato.status%TYPE;
  v_contrato_id       contrato.contrato_id%TYPE;
  v_contrato_horas_id contrato_horas_usu.contrato_horas_id%TYPE;
  v_horas_aloc        contrato_horas_usu.horas_aloc%TYPE;
  v_usuario_id        contrato_horas_usu.usuario_id%TYPE;
  v_usuario           pessoa.apelido%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas_usu
   WHERE contrato_horas_usu_id = p_contrato_horas_usu_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato horas/usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         hu.usuario_id
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id
    FROM contrato           ct,
         contrato_horas_usu hu,
         contrato_horas     ch
   WHERE hu.contrato_horas_usu_id = p_contrato_horas_usu_id
     AND hu.contrato_horas_id = ch.contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = v_usuario_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_USU_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias dos parametros de entrada
  ------------------------------------------------------------
  IF numero_validar(p_horas_aloc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas (' || p_horas_aloc || ').';
   RAISE v_exception;
  END IF;
  --
  v_horas_aloc := nvl(round(numero_converter(p_horas_aloc), 2), 0);
  --
  IF v_horas_aloc < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas (' || p_horas_aloc || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_horas_usu
     SET horas_aloc = v_horas_aloc
   WHERE contrato_horas_usu_id = p_contrato_horas_usu_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração de horas alocadas - usuário: ' || v_usuario;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END horas_usu_atualizar;
 --
 --
 PROCEDURE horas_usu_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/06/2022
  -- DESCRICAO: Exclusao de alocacao de horas no contrato para um usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN contrato.empresa_id%TYPE,
  p_contrato_id             IN contrato.contrato_id%TYPE,
  p_usuario_id              IN contrato_horas_usu.usuario_id%TYPE,
  p_vetor_contrato_horas_id IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS

  v_qt                      INTEGER;
  v_numero_contrato         contrato.numero%TYPE;
  v_status_contrato         contrato.status%TYPE;
  v_contrato_horas_id       contrato_horas_usu.contrato_horas_id%TYPE;
  v_exception               EXCEPTION;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_contrato_horas_id VARCHAR2(4000);
  v_usuario                 pessoa.apelido%TYPE;
  v_xml_atual               CLOB;
 BEGIN
  v_qt := 0;
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
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_USU_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador             := '|';
  v_vetor_contrato_horas_id := rtrim(p_vetor_contrato_horas_id);
  --
  WHILE nvl(length(rtrim(v_vetor_contrato_horas_id)), 0) > 0
  LOOP
   v_contrato_horas_id := nvl(to_number(prox_valor_retornar(v_vetor_contrato_horas_id,
                                                            v_delimitador)),
                              0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_horas
    WHERE contrato_horas_id = v_contrato_horas_id
      AND contrato_id = p_contrato_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Contrato/horas inválido (' || to_char(v_contrato_horas_id) || ').';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM contrato_horas_usu
    WHERE contrato_horas_id = v_contrato_horas_id
      AND usuario_id = p_usuario_id;

  END LOOP; -- fim do loop por vetor
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Exclusão de horas alocadas - usuário: ' || v_usuario;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END horas_usu_excluir;
 --
 --
 PROCEDURE valores_sugeridos_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/09/2014
  -- DESCRICAO: Alteração de valores de custo e venda padrao (sugeridos) instanciados
  --   no contrato_horas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/05/2020  Eliminacao do papel_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_custo_hora_pdr    IN VARCHAR2,
  p_venda_hora_pdr    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                INTEGER;
  v_contrato_id       contrato.contrato_id%TYPE;
  v_numero_contrato   contrato.numero%TYPE;
  v_status_contrato   contrato.status%TYPE;
  v_nome_area         area.nome%TYPE;
  v_area_id           area.area_id%TYPE;
  v_usuario_id        contrato_horas.usuario_id%TYPE;
  v_venda_hora_pdr    contrato_horas.venda_hora_pdr%TYPE;
  v_venda_hora_pdr_en contrato_horas.venda_hora_pdr%TYPE;
  v_custo_hora_pdr    contrato_horas.custo_hora_pdr%TYPE;
  v_custo_hora_pdr_en contrato_horas.custo_hora_pdr%TYPE;
  v_nivel             contrato_horas.nivel%TYPE;
  v_nome_usuario      pessoa.apelido%TYPE;
  v_cargo_id          cargo.cargo_id%TYPE;
  v_nome_cargo        cargo.nome%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_antes         CLOB;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.status,
         ct.contrato_id,
         ch.usuario_id,
         ch.nivel,
         ch.cargo_id,
         ch.area_id
    INTO v_numero_contrato,
         v_status_contrato,
         v_contrato_id,
         v_usuario_id,
         v_nivel,
         v_cargo_id,
         v_area_id
    FROM contrato       ct,
         contrato_horas ch
   WHERE ch.contrato_horas_id = p_contrato_horas_id
     AND ch.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_HORA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;

  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;

  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  -- venda padrao (preco sugerido)
  IF TRIM(p_venda_hora_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço da hora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_hora_pdr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido (' || p_venda_hora_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_pdr := nvl(moeda_converter(p_venda_hora_pdr), 0);
  --
  IF v_venda_hora_pdr < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido (' || p_venda_hora_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  -- encripta para salvar
  v_venda_hora_pdr_en := util_pkg.num_encode(v_venda_hora_pdr);
  --
  IF v_venda_hora_pdr_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_pdr, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  -- custo padrao (custo sugerido)
  IF TRIM(p_custo_hora_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do custo da hora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_custo_hora_pdr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo da hora inválido (' || p_custo_hora_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo_hora_pdr := nvl(moeda_converter(p_custo_hora_pdr), 0);
  --
  IF v_custo_hora_pdr < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo da hora inválido (' || p_custo_hora_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  -- encripta para salvar
  v_custo_hora_pdr_en := util_pkg.num_encode(v_custo_hora_pdr);
  --
  IF v_custo_hora_pdr_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora_pdr, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_horas
     SET venda_hora_pdr = v_venda_hora_pdr_en,
         custo_hora_pdr = v_custo_hora_pdr_en
   WHERE contrato_horas_id = p_contrato_horas_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de valores sugeridos: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de valores sugeridos: ' || v_nome_usuario || ' / ' || v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END valores_sugeridos_atualizar;
 --
 --
 PROCEDURE servico_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/02/2021
  -- DESCRICAO: Inclusão de servico no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/06/2022  Atualiza contrato_horas sem servico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_id        IN contrato_servico.contrato_id%TYPE,
  p_servico_id         IN contrato_servico.servico_id%TYPE,
  p_emp_faturar_por_id IN contrato.emp_faturar_por_id%TYPE,
  p_data_inicio        IN VARCHAR2,
  p_data_termino       IN VARCHAR2,
  p_descricao          IN VARCHAR2,
  p_cod_externo        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                  INTEGER;
  v_numero_contrato     contrato.numero%TYPE;
  v_status_contrato     contrato.status%TYPE;
  v_contrato_servico_id contrato_servico.contrato_servico_id%TYPE;
  v_data_inicio         contrato_servico.data_inicio%TYPE;
  v_data_termino        contrato_servico.data_termino%TYPE;
  v_nome_servico        servico.nome%TYPE;
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_servico_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_externo)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo não pode ter mais que 20 caracteres (' || p_cod_externo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_servico
    FROM servico
   WHERE servico_id = p_servico_id;
  --
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_inicio  := data_converter(p_data_inicio);
  v_data_termino := data_converter(p_data_termino);
  --
  IF v_data_inicio > v_data_termino THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início não pode ser maior que a data de término (' || p_data_inicio ||
                 ' - ' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_contrato_servico.nextval
    INTO v_contrato_servico_id
    FROM dual;
  --
  INSERT INTO contrato_servico
   (contrato_servico_id,
    contrato_id,
    servico_id,
    emp_faturar_por_id,
    cod_externo,
    data_inicio,
    data_termino,
    descricao)
  VALUES
   (v_contrato_servico_id,
    p_contrato_id,
    p_servico_id,
    zvl(p_emp_faturar_por_id, NULL),
    TRIM(p_cod_externo),
    v_data_inicio,
    v_data_termino,
    TRIM(p_descricao));
  --
  -- passa eventuais parcelas sem servico
  -- para o servico adicionado ao contrato
  UPDATE parcela_contrato
     SET contrato_servico_id = v_contrato_servico_id
   WHERE contrato_id = p_contrato_id
     AND contrato_servico_id IS NULL;
  --
  -- passa eventuais estimativas de horas sem servico
  -- para o servico adicionado ao contrato
  UPDATE contrato_horas
     SET contrato_servico_id = v_contrato_servico_id
   WHERE contrato_id = p_contrato_id
     AND contrato_servico_id IS NULL;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Inclusão do produto ' || v_nome_servico;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END servico_adicionar;
 --
 --
 PROCEDURE servico_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 23/03/2021
  -- DESCRICAO: Atualizacao de servico do contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_servico_id          IN contrato_servico.servico_id%TYPE,
  p_emp_faturar_por_id  IN contrato.emp_faturar_por_id%TYPE,
  p_data_inicio         IN VARCHAR2,
  p_data_termino        IN VARCHAR2,
  p_descricao           IN VARCHAR2,
  p_cod_externo         IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_data_inicio     contrato_servico.data_inicio%TYPE;
  v_data_termino    contrato_servico.data_termino%TYPE;
  v_nome_servico    servico.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(contrato_id)
    INTO v_contrato_id
    FROM contrato_servico
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_servico_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_externo)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo não pode ter mais que 20 caracteres (' || p_cod_externo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do término é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_inicio  := data_converter(p_data_inicio);
  v_data_termino := data_converter(p_data_termino);
  --
  IF v_data_inicio > v_data_termino THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início não pode ser maior que a data de término (' || p_data_inicio ||
                 ' - ' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_servico
    FROM servico
   WHERE servico_id = p_servico_id;
  --
  -- verifica se existem parcelas com faturamento
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE contrato_id = v_contrato_id
     AND contrato_servico_id = p_contrato_servico_id
     AND contrato_pkg.status_parcela_retornar(parcela_contrato_id) IN ('FATU', 'PARC');
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem parcelas já faturadas para esse produto.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_servico
     SET servico_id         = p_servico_id,
         emp_faturar_por_id = zvl(p_emp_faturar_por_id, NULL),
         cod_externo        = TRIM(p_cod_externo),
         data_inicio        = v_data_inicio,
         data_termino       = v_data_termino,
         descricao          = TRIM(p_descricao)
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração do produto ' || v_nome_servico;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_atualizar;
 --
 --
 PROCEDURE servico_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/02/2021
  -- DESCRICAO: Exclusao de servico do contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         25/07/2024  Apagando registros filhos do contrato_servico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_servico_id      servico.servico_id%TYPE;
  v_nome_servico    servico.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(contrato_id),
         MAX(servico_id)
    INTO v_contrato_id,
         v_servico_id
    FROM contrato_servico
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_servico
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  -- verifica se existem parcelas com faturamento
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE contrato_id = v_contrato_id
     AND contrato_servico_id = p_contrato_servico_id
     AND contrato_pkg.status_parcela_retornar(parcela_contrato_id) IN ('FATU', 'PARC');
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem parcelas já faturadas para esse produto.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CONTRATO_SERVICO_EXCLUIR',
                           p_empresa_id,
                           p_contrato_servico_id,
                           NULL,
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
  -- exclui eventuais parcelas
  DELETE FROM parcela_contrato
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  DELETE FROM contrato_serv_valor
   WHERE contrato_servico_id = p_contrato_servico_id;
  --ALCBO_250724
  DELETE FROM contrato_item
   WHERE contrato_servico_id = p_contrato_servico_id;
  --ALCBO_250724
  DELETE FROM contrato_horas
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  DELETE FROM contrato_servico
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Exclusão do produto ' || v_nome_servico;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_excluir;
 --
 --
 PROCEDURE servico_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/01/2022
  -- DESCRICAO: Faz uma integracao forcada de servico do contrato, independente
  --   do status do parcelamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_servico_id      servico.servico_id%TYPE;
  v_nome_servico    servico.nome%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(contrato_id),
         MAX(servico_id)
    INTO v_contrato_id,
         v_servico_id
    FROM contrato_servico
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_servico
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- integracao com sistemas externos
  it_controle_pkg.integrar('CONTRATO_SERVICO_FORCAR',
                           p_empresa_id,
                           p_contrato_servico_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Integração do contrato/produto: ' || to_char(p_contrato_servico_id) || ' - ' ||
                      v_nome_servico;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_integrar;
 --
 --
 PROCEDURE servico_valor_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/02/2021
  -- DESCRICAO: Inclusão de valor de servico no contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/05/2022  Novos parametros de responsavel
  -- Silvia            12/07/2022  Consistencia de responsavel obrigatorio
  -- Silvia            01/08/2022  Enderecamento automatico do responsavel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN contrato.empresa_id%TYPE,
  p_contrato_servico_id  IN contrato_servico.contrato_servico_id%TYPE,
  p_emp_resp_id          IN contrato_serv_valor.emp_resp_id%TYPE,
  p_valor_servico        IN VARCHAR2,
  p_usuario_resp_id      IN contrato_serv_valor.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN contrato_serv_valor.unid_negocio_resp_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS

  v_qt               INTEGER;
  v_numero_contrato  contrato.numero%TYPE;
  v_status_contrato  contrato.status%TYPE;
  v_nome_servico     servico.nome%TYPE;
  v_contrato_id      contrato_servico.contrato_id%TYPE;
  v_valor_servico    contrato_serv_valor.valor_servico%TYPE;
  v_servico_id       servico.servico_id%TYPE;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_atual        CLOB;
  v_usa_resp_serv    VARCHAR2(10);
  v_obriga_resp_serv VARCHAR2(10);
  --
 BEGIN
  v_qt               := 0;
  v_usa_resp_serv    := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_RESP_SERV_OPORT');
  v_obriga_resp_serv := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_RESP_SERV_OPORT');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(contrato_id),
         MAX(servico_id)
    INTO v_contrato_id,
         v_servico_id
    FROM contrato_servico
   WHERE contrato_servico_id = p_contrato_servico_id;
  --
  IF v_contrato_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato/produto não existe.';
   RAISE v_exception;
  END IF;

  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_servico
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  IF nvl(p_emp_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa responsável (' || to_char(p_emp_resp_id) ||
                 ') não existe na empresa operacional (' || to_char(p_empresa_id) || ').';

   RAISE v_exception;
  END IF;
  --
  IF v_usa_resp_serv = 'S' AND v_obriga_resp_serv = 'S' AND nvl(p_usuario_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pelo produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_servico) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_servico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do produto inválido (' || p_valor_servico || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_servico := nvl(moeda_converter(p_valor_servico), 0);
  --
  IF v_valor_servico < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do produto inválido (' || p_valor_servico || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO contrato_serv_valor
   (contrato_serv_valor_id,
    contrato_servico_id,
    emp_resp_id,
    usuario_id,
    data_refer,
    valor_servico,
    usuario_resp_id,
    unid_negocio_resp_id,
    flag_oport)
  VALUES
   (seq_contrato_serv_valor.nextval,
    p_contrato_servico_id,
    p_emp_resp_id,
    p_usuario_sessao_id,
    trunc(SYSDATE),
    v_valor_servico,
    zvl(p_usuario_resp_id, NULL),
    zvl(p_unid_negocio_resp_id, NULL),
    'N');
  --
  ------------------------------------------------------------
  -- enderecamento automatico do usuario responsavel
  ------------------------------------------------------------
  IF nvl(p_usuario_resp_id, 0) > 0 THEN
   -- endereca o usuario responsavel.
   contrato_pkg.enderecar_usuario(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_contrato_id,
                                  p_usuario_resp_id,
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
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Inclusão de valor do produto ' || v_nome_servico || ': R$ ' ||
                      moeda_mostrar(v_valor_servico, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_valor_adicionar;
 --
 --
 PROCEDURE servico_valor_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/02/2021
  -- DESCRICAO: Atualizacao  de valor do servico do contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/05/2022  Novos parametros de responsavel
  -- Silvia            12/07/2022  Consistencia de responsavel obrigatorio
  -- Silvia            01/08/2022  Enderecamento automatico do responsavel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_serv_valor_id IN contrato_serv_valor.contrato_serv_valor_id%TYPE,
  p_emp_resp_id            IN contrato_serv_valor.emp_resp_id%TYPE,
  p_valor_servico          IN VARCHAR2,
  p_usuario_resp_id        IN contrato_serv_valor.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id   IN contrato_serv_valor.unid_negocio_resp_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS

  v_qt               INTEGER;
  v_contrato_id      contrato.contrato_id%TYPE;
  v_numero_contrato  contrato.numero%TYPE;
  v_status_contrato  contrato.status%TYPE;
  v_servico_id       servico.servico_id%TYPE;
  v_nome_servico     servico.nome%TYPE;
  v_valor_servico    contrato_serv_valor.valor_servico%TYPE;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_atual        CLOB;
  v_usa_resp_serv    VARCHAR2(10);
  v_obriga_resp_serv VARCHAR2(10);
  --
 BEGIN
  v_qt               := 0;
  v_usa_resp_serv    := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_RESP_SERV_OPORT');
  v_obriga_resp_serv := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_RESP_SERV_OPORT');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_serv_valor
   WHERE contrato_serv_valor_id = p_contrato_serv_valor_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse valor de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT cs.contrato_id,
         cs.servico_id
    INTO v_contrato_id,
         v_servico_id
    FROM contrato_serv_valor cv,
         contrato_servico    cs
   WHERE cv.contrato_serv_valor_id = p_contrato_serv_valor_id
     AND cv.contrato_servico_id = cs.contrato_servico_id;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_emp_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa responsável (' || to_char(p_emp_resp_id) ||
                 ') não existe na empresa operacional (' || to_char(p_empresa_id) || ').';

   RAISE v_exception;
  END IF;
  --
  IF v_usa_resp_serv = 'S' AND v_obriga_resp_serv = 'S' AND nvl(p_usuario_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável pelo produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_servico) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_servico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do produto inválido (' || p_valor_servico || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_servico := nvl(moeda_converter(p_valor_servico), 0);
  --
  IF v_valor_servico < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do produto inválido (' || p_valor_servico || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_serv_valor
     SET emp_resp_id          = p_emp_resp_id,
         valor_servico        = v_valor_servico,
         data_refer           = trunc(SYSDATE),
         usuario_id           = p_usuario_sessao_id,
         usuario_resp_id      = zvl(p_usuario_resp_id, NULL),
         unid_negocio_resp_id = zvl(p_unid_negocio_resp_id, NULL)
   WHERE contrato_serv_valor_id = p_contrato_serv_valor_id;
  --
  ------------------------------------------------------------
  -- enderecamento automatico do usuario responsavel
  ------------------------------------------------------------
  IF nvl(p_usuario_resp_id, 0) > 0 THEN
   -- endereca o usuario responsavel.
   contrato_pkg.enderecar_usuario(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_contrato_id,
                                  p_usuario_resp_id,
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
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Alteração de valor do produto ' || v_nome_servico || ': R$ ' ||
                      moeda_mostrar(v_valor_servico, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_valor_atualizar;
 --
 --
 PROCEDURE servico_valor_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/02/2021
  -- DESCRICAO: Exclusao de valor do servico do contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_serv_valor_id IN contrato_serv_valor.contrato_serv_valor_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS

  v_qt                  INTEGER;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_numero_contrato     contrato.numero%TYPE;
  v_status_contrato     contrato.status%TYPE;
  v_servico_id          servico.servico_id%TYPE;
  v_nome_servico        servico.nome%TYPE;
  v_contrato_servico_id contrato_serv_valor.contrato_servico_id%TYPE;
  v_valor_servico       contrato_serv_valor.valor_servico%TYPE;
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_serv_valor
   WHERE contrato_serv_valor_id = p_contrato_serv_valor_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse valor de produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT cs.contrato_id,
         cs.servico_id,
         cv.valor_servico,
         cs.contrato_servico_id
    INTO v_contrato_id,
         v_servico_id,
         v_valor_servico,
         v_contrato_servico_id
    FROM contrato_serv_valor cv,
         contrato_servico    cs
   WHERE cv.contrato_serv_valor_id = p_contrato_serv_valor_id
     AND cv.contrato_servico_id = cs.contrato_servico_id;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_A',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM contrato_serv_valor
   WHERE contrato_serv_valor_id = p_contrato_serv_valor_id;
  --
  /*
    -- verifica se sobraram valores para o servico.
    SELECT COUNT(*)
      INTO v_qt
      FROM contrato_serv_valor
     WHERE contrato_servico_id = v_contrato_servico_id;
  --
    IF v_qt = 0 THEN
       -- verifica se existem parcelas com faturamento
       SELECT COUNT(*)
         INTO v_qt
         FROM parcela_contrato
        WHERE contrato_id = v_contrato_id
          AND contrato_servico_id = v_contrato_servico_id
          AND contrato_pkg.status_parcela_retornar(parcela_contrato_id) IN ('FATU','PARC');
       --
       IF v_qt > 0 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Existem parcelas já faturadas para esse produto.';
          RAISE v_exception;
       END IF;
    ELSE
       -- exclui eventuais parcelas
       DELETE FROM parcela_contrato
        WHERE contrato_servico_id = v_contrato_servico_id;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := 'Exclusão de valor do produto ' || v_nome_servico || ': R$ ' ||
                      moeda_mostrar(v_valor_servico, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END servico_valor_excluir;
 --
 --
 PROCEDURE parcela_renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: subrotina que renumera as parcelas de um contrato.
  --      NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_contrato_id         IN contrato_servico.contrato_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt          INTEGER;
  v_num_parcela parcela_contrato.num_parcela%TYPE;
  v_exception   EXCEPTION;
  --
  -- cursor de parcelas
  CURSOR c_par IS
   SELECT parcela_contrato_id
     FROM parcela_contrato
    WHERE contrato_id = p_contrato_id
      AND nvl(contrato_servico_id, 0) = nvl(p_contrato_servico_id, 0)
    ORDER BY data_vencim
      FOR UPDATE OF num_parcela;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_num_parcela := 0;
  --
  FOR r_par IN c_par
  LOOP
   v_num_parcela := v_num_parcela + 1;
   --
   UPDATE parcela_contrato
      SET num_parcela = v_num_parcela
    WHERE parcela_contrato_id = r_par.parcela_contrato_id;

  END LOOP;
  --
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
 END parcela_renumerar;
 --
 --
 PROCEDURE parcelas_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: geracao de parcelas do CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/08/2022  Detalhamento do histórico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_id         IN contrato_servico.contrato_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_num_parcelas        IN VARCHAR2,
  p_data_prim_parcela   IN VARCHAR2,
  p_valor_parcela       IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt                INTEGER;
  v_numero_contrato   contrato.numero%TYPE;
  v_status_contrato   contrato.status%TYPE;
  v_status_parcel     contrato.status_parcel%TYPE;
  v_num_parcelas      NUMBER(10);
  v_num_parcela       parcela_contrato.num_parcela%TYPE;
  v_data_prim_parcela parcela_contrato.data_vencim%TYPE;
  v_data_vencim       parcela_contrato.data_vencim%TYPE;
  v_valor_parcela     parcela_contrato.valor_parcela%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_antes         CLOB;
  v_xml_atual         CLOB;
  v_nome_servico      servico.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
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
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_parcel
    INTO v_numero_contrato,
         v_status_contrato,
         v_status_parcel
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_PARCELA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcel = 'PRON' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do parcelamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF inteiro_validar(p_num_parcelas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de parcelas inválido (' || p_num_parcelas || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_parcelas := nvl(to_number(p_num_parcelas), 0);
  --
  IF v_num_parcelas <= 0 OR v_num_parcelas > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de parcelas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_prim_parcela) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prim_parcela) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida (' || p_data_prim_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prim_parcela := data_converter(p_data_prim_parcela);
  --
  IF TRIM(p_valor_parcela) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor da parcela é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_parcela) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da parcela inválido (' || p_valor_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_parcela := nvl(moeda_converter(p_valor_parcela), 0);
  --
  IF v_valor_parcela <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor inválido (' || p_valor_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data_vencim := v_data_prim_parcela;
  --
  SELECT nvl(MAX(num_parcela), 0)
    INTO v_num_parcela
    FROM parcela_contrato
   WHERE contrato_id = p_contrato_id
     AND nvl(contrato_servico_id, 0) = nvl(p_contrato_servico_id, 0);
  --
  IF nvl(p_contrato_servico_id, 0) > 0 THEN
   -- recupera o nome do servico para usar no historico
   SELECT se.nome
     INTO v_nome_servico
     FROM contrato_servico cs,
          servico          se
    WHERE cs.contrato_servico_id = p_contrato_servico_id
      AND cs.servico_id = se.servico_id;

  END IF;
  --
  FOR v_par IN 1 .. v_num_parcelas
  LOOP
   v_num_parcela := v_num_parcela + 1;
   --
   INSERT INTO parcela_contrato
    (parcela_contrato_id,
     contrato_id,
     contrato_servico_id,
     num_parcela,
     data_vencim,
     valor_parcela)
   VALUES
    (seq_parcela_contrato.nextval,
     p_contrato_id,
     zvl(p_contrato_servico_id, NULL),
     v_num_parcela,
     v_data_vencim,
     v_valor_parcela);
   --
   v_data_vencim := add_months(v_data_prim_parcela, v_par);
  END LOOP;
  --
  -- renumera parcelas
  contrato_pkg.parcela_renumerar(p_usuario_sessao_id,
                                 p_contrato_id,
                                 p_contrato_servico_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE contrato
     SET status_parcel = 'PREP'
   WHERE contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  IF v_nome_servico IS NULL THEN
   v_compl_histor := 'Inclusão de ' || to_char(v_num_parcelas) || ' parcelas no valor de R$ ' ||
                     moeda_mostrar(v_valor_parcela, 'S') || ' cada com primeiro vencimento em ' ||
                     data_mostrar(v_data_prim_parcela) || '.';
  ELSE
   v_compl_histor := 'Inclusão de ' || to_char(v_num_parcelas) || ' parcelas no produto ' ||
                     v_nome_servico || ' no valor de R$ ' || moeda_mostrar(v_valor_parcela, 'S') ||
                     ' cada com primeiro vencimento em ' || data_mostrar(v_data_prim_parcela) || '.';
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END parcelas_gerar;
 --
 --
 PROCEDURE parcela_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: alteracao de parcela do CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/08/2022  Detalhamento do histórico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_data_vencim         IN VARCHAR2,
  p_valor_parcela       IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt                  INTEGER;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_numero_contrato     contrato.numero%TYPE;
  v_status_contrato     contrato.status%TYPE;
  v_status_parcel       contrato.status_parcel%TYPE;
  v_contrato_servico_id parcela_contrato.contrato_servico_id%TYPE;
  v_data_vencim         parcela_contrato.data_vencim%TYPE;
  v_valor_parcela       parcela_contrato.valor_parcela%TYPE;
  v_data_vencim_old     parcela_contrato.data_vencim%TYPE;
  v_valor_parcela_old   parcela_contrato.valor_parcela%TYPE;
  v_status_parcela      VARCHAR2(100);
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  v_nome_servico        servico.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa parcela não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT contrato_id,
         nvl(contrato_servico_id, 0),
         contrato_pkg.status_parcela_retornar(parcela_contrato_id),
         data_vencim,
         valor_parcela
    INTO v_contrato_id,
         v_contrato_servico_id,
         v_status_parcela,
         v_data_vencim_old,
         v_valor_parcela_old
    FROM parcela_contrato
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  SELECT numero,
         status,
         status_parcel
    INTO v_numero_contrato,
         v_status_contrato,
         v_status_parcel
    FROM contrato
   WHERE contrato_id = v_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_PARCELA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcel = 'PRON' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do parcelamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcela <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da parcela não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data_vencim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_vencim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida (' || p_data_vencim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_vencim := data_converter(p_data_vencim);
  --
  IF TRIM(p_valor_parcela) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor da parcela é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_parcela) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da parcela inválido (' || p_valor_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_parcela := nvl(moeda_converter(p_valor_parcela), 0);
  --
  IF v_valor_parcela <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da parcela inválido (' || p_valor_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_contrato_servico_id, 0) > 0 THEN
   -- recupera o nome do servico para o historico
   SELECT se.nome
     INTO v_nome_servico
     FROM contrato_servico cs,
          servico          se
    WHERE cs.contrato_servico_id = v_contrato_servico_id
      AND cs.servico_id = se.servico_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE parcela_contrato
     SET data_vencim   = v_data_vencim,
         valor_parcela = v_valor_parcela
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  -- renumera parcelas
  contrato_pkg.parcela_renumerar(p_usuario_sessao_id,
                                 v_contrato_id,
                                 v_contrato_servico_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  IF v_nome_servico IS NULL THEN
   v_compl_histor := 'Alteração de parcela com vencimento em ' || data_mostrar(v_data_vencim_old) ||
                     ' no valor de R$ ' || moeda_mostrar(v_valor_parcela_old, 'S') ||
                     ' para vencimento em ' || data_mostrar(v_data_vencim) || ' e valor de R$ ' ||
                     moeda_mostrar(v_valor_parcela, 'S') || '.';
  ELSE
   v_compl_histor := 'Alteração de parcela com vencimento em ' || data_mostrar(v_data_vencim_old) ||
                     ' no valor de R$ ' || moeda_mostrar(v_valor_parcela_old, 'S') ||
                     ' para vencimento em ' || data_mostrar(v_data_vencim) || ' e valor de R$ ' ||
                     moeda_mostrar(v_valor_parcela, 'S') || ' do produto ' || v_nome_servico || '.';
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END parcela_alterar;
 --
 --
 PROCEDURE parcela_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: exclusao de parcela do CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/08/2022  Detalhamento do histórico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS

  v_qt                  INTEGER;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_numero_contrato     contrato.numero%TYPE;
  v_status_contrato     contrato.status%TYPE;
  v_status_parcel       contrato.status_parcel%TYPE;
  v_contrato_servico_id parcela_contrato.contrato_servico_id%TYPE;
  v_data_vencim         parcela_contrato.data_vencim%TYPE;
  v_valor_parcela       parcela_contrato.valor_parcela%TYPE;
  v_status_parcela      VARCHAR2(100);
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  v_nome_servico        servico.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa parcela não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.contrato_id,
         ct.numero,
         ct.status,
         contrato_pkg.status_parcela_retornar(pc.parcela_contrato_id),
         nvl(pc.contrato_servico_id, 0),
         pc.data_vencim,
         pc.valor_parcela
    INTO v_contrato_id,
         v_numero_contrato,
         v_status_contrato,
         v_status_parcela,
         v_contrato_servico_id,
         v_data_vencim,
         v_valor_parcela
    FROM parcela_contrato pc,
         contrato         ct
   WHERE pc.parcela_contrato_id = p_parcela_contrato_id
     AND pc.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_PARCELA_C',
                                v_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcel = 'PRON' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do parcelamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcela <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da parcela não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_contrato_servico_id, 0) > 0 THEN
   -- recupera o nome do servico para o historico
   SELECT se.nome
     INTO v_nome_servico
     FROM contrato_servico cs,
          servico          se
    WHERE cs.contrato_servico_id = v_contrato_servico_id
      AND cs.servico_id = se.servico_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_fatur_ctr
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe faturamento associado a essa parcela.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM abatimento_ctr
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe abatimento associado a essa parcela.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM parcela_contrato
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  -- renumera parcelas
  contrato_pkg.parcela_renumerar(p_usuario_sessao_id,
                                 v_contrato_id,
                                 v_contrato_servico_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE contrato_id = v_contrato_id;
  --
  IF v_qt = 0 THEN
   UPDATE contrato
      SET status_parcel = 'NAOI'
    WHERE contrato_id = v_contrato_id;

  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(v_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  IF v_nome_servico IS NULL THEN
   v_compl_histor := 'Exclusão de parcela com vencimento em ' || data_mostrar(v_data_vencim) ||
                     ' no valor de R$ ' || moeda_mostrar(v_valor_parcela, 'S') || '.';
  ELSE
   v_compl_histor := 'Exclusão de parcela com vencimento em ' || data_mostrar(v_data_vencim) ||
                     ' no valor de R$ ' || moeda_mostrar(v_valor_parcela, 'S') || ' do produto ' ||
                     v_nome_servico || '.';
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
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
 END parcela_excluir;
 --
 --
 PROCEDURE parcelamento_terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: termina o parcelamento de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/02/2021  Consistencia do parcelamento x valor do servico
  -- Silvia            19/10/2022  Atualiza eventual registro de parcelam em contrato_elab
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                  INTEGER;
  v_numero_contrato     contrato.numero%TYPE;
  v_status_contrato     contrato.status%TYPE;
  v_status_parcel       contrato.status_parcel%TYPE;
  v_contratante_id      contrato.contratante_id%TYPE;
  v_valor_parcelas      parcela_contrato.valor_parcela%TYPE;
  v_exception           EXCEPTION;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
  v_obriga_cli_completo VARCHAR2(20);
  --
  CURSOR c_se IS
   SELECT cs.contrato_servico_id,
          se.servico_id,
          se.nome AS nome_servico,
          nvl(SUM(cv.valor_servico), 0) AS valor_servico
     FROM contrato_servico    cs,
          contrato_serv_valor cv,
          servico             se
    WHERE cs.contrato_id = p_contrato_id
      AND cs.servico_id = se.servico_id
      AND cs.contrato_servico_id = cv.contrato_servico_id(+)
    GROUP BY cs.contrato_servico_id,
             se.servico_id,
             se.nome
    ORDER BY se.nome;
  --
 BEGIN
  v_qt                  := 0;
  v_obriga_cli_completo := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_CLICTR_COMPLETO');
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
   p_erro_msg := 'Essa contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_parcel,
         contratante_id
    INTO v_numero_contrato,
         v_status_contrato,
         v_status_parcel,
         v_contratante_id
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_PARCELA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcel IN ('NAOI', 'PRON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do parcelamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela_contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Parcelamento ainda não iniciado.';
   RAISE v_exception;
  END IF;
  --
  IF v_obriga_cli_completo = 'S' THEN
   IF pessoa_pkg.dados_integr_verificar(v_contratante_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para se terminar ou indicar como Pronto o parcelamento ' ||
                  'do Contrato, é necessário que as informações do Cliente ' ||
                  'estejam completas (CNPJ e endereço).';
    RAISE v_exception;
   END IF;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            v_contratante_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET status_parcel     = 'PRON',
         usuario_parcel_id = p_usuario_sessao_id
   WHERE contrato_id = p_contrato_id;
  --
  -- atualiza eventual registro de parcelamento
  -- em contrato_elab
  UPDATE contrato_elab
     SET status        = 'PRON',
         data_execucao = SYSDATE,
         usuario_id    = p_usuario_sessao_id
   WHERE contrato_id = p_contrato_id
     AND cod_contrato_elab = 'PARC';
  --
  ------------------------------------------------------------
  -- consistencias finais e integracao
  ------------------------------------------------------------
  FOR r_se IN c_se
  LOOP
   IF r_se.valor_servico = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O produto ' || r_se.nome_servico || ' não possui valor.';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(SUM(valor_parcela), 0)
     INTO v_valor_parcelas
     FROM parcela_contrato
    WHERE contrato_id = p_contrato_id
      AND contrato_servico_id = r_se.contrato_servico_id;
   --
   IF v_valor_parcelas <> r_se.valor_servico THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor total do produto ' || r_se.nome_servico ||
                  ' não bate com o valor total das parcelas.';
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- integracao com sistemas externos
   ------------------------------------------------------------
   it_controle_pkg.integrar('CONTRATO_SERVICO_ATUALIZAR',
                            p_empresa_id,
                            r_se.contrato_servico_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'TERMINAR_PARCELAM',
                   v_identif_objeto,
                   p_contrato_id,
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
 END parcelamento_terminar;
 --
 --
 PROCEDURE parcelamento_revisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/08/2018
  -- DESCRICAO: revisa o parcelamento de CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/10/2022  Atualiza eventual registro de parcelam em contrato_elab
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_status_parcel   contrato.status_parcel%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
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
   p_erro_msg := 'Essa contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_parcel
    INTO v_numero_contrato,
         v_status_contrato,
         v_status_parcel
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CONTRATO_PARCELA_C',
                                p_contrato_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_parcel NOT IN ('PRON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do parcelamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_rev) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo_rev)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_rev)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato
     SET status_parcel     = 'PREP',
         usuario_revpar_id = p_usuario_sessao_id,
         motivo_revpar     = TRIM(p_motivo_rev),
         compl_revpar      = TRIM(p_compl_rev)
   WHERE contrato_id = p_contrato_id;
  --
  -- atualiza eventual registro de parcelamento
  -- em contrato_elab
  UPDATE contrato_elab
     SET status        = 'PEND',
         data_execucao = NULL,
         usuario_id    = p_usuario_sessao_id
   WHERE contrato_id = p_contrato_id
     AND cod_contrato_elab = 'PARC';
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  v_compl_histor   := TRIM(p_compl_rev);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'REVISAR_PARCELAM',
                   v_identif_objeto,
                   p_contrato_id,
                   v_compl_histor,
                   TRIM(p_motivo_rev),
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
 END parcelamento_revisar;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 04/09/2014
  -- DESCRICAO: Adicionar arquivo no CONTRATO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_contrato_id       IN arquivo_contrato.contrato_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_A', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa alteração.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'CONTRATO';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_contrato_id,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  v_compl_histor := 'Anexação de arquivo no Contrato (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_contrato_id,
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
 END arquivo_adicionar;
 --
 --
 PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 04/09/2014
  -- DESCRICAO: Excluir arquivo do CONTRATO
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
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
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
    FROM contrato         ct,
         arquivo_contrato ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.contrato_id = ct.contrato_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ac.contrato_id,
         ar.nome_original
    INTO v_contrato_id,
         v_nome_original
    FROM arquivo_contrato ac,
         arquivo          ar
   WHERE ac.arquivo_id = p_arquivo_id
     AND ac.arquivo_id = ar.arquivo_id;
  --
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_A', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa alteração.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  v_compl_histor := 'Exclusão de arquivo do Contrato (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
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
 END arquivo_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/02/2017
  -- DESCRICAO: Subrotina que gera o xml de contrato para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_contrato_id IN contrato.contrato_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS

  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_na IS
   SELECT na.codigo,
          na.nome,
          numero_mostrar(cn.valor_padrao, 6, 'N') valor_padrao,
          na.mod_calculo,
          na.ordem
     FROM contrato_nitem_pdr cn,
          natureza_item      na
    WHERE na.natureza_item_id = cn.natureza_item_id
      AND cn.contrato_id = p_contrato_id
    ORDER BY na.ordem;
  --
  CURSOR c_pa IS
   SELECT nvl(se.nome, 'ND') AS servico,
          num_parcela,
          data_mostrar(data_vencim) data_parcela,
          numero_mostrar(valor_parcela, 2, 'N') valor_parcela,
          contrato_pkg.status_parcela_retornar(parcela_contrato_id) status
     FROM parcela_contrato pc,
          contrato_servico cs,
          servico          se
    WHERE pc.contrato_id = p_contrato_id
      AND pc.contrato_servico_id = cs.contrato_servico_id(+)
      AND cs.servico_id = se.servico_id(+)
    ORDER BY 1,
             2;
  --
  CURSOR c_se IS
   SELECT se.nome AS nome_servico,
          pr.apelido AS empresa_resp,
          moeda_mostrar(cv.valor_servico, 'S') AS valor_servico,
          data_mostrar(cv.data_refer) AS data_refer,
          pe.apelido AS usuario,
          cs.cod_externo
     FROM contrato_servico    cs,
          contrato_serv_valor cv,
          servico             se,
          pessoa              pe,
          pessoa              pr
    WHERE cs.contrato_id = p_contrato_id
      AND cs.servico_id = se.servico_id
      AND cs.contrato_servico_id = cv.contrato_servico_id
      AND cv.usuario_id = pe.usuario_id
      AND cv.emp_resp_id = pr.pessoa_id
    ORDER BY se.nome,
             pr.apelido,
             cv.data_refer;
  --
  -- horas planejadas
  CURSOR c_ho IS
   SELECT ch.data,
          ch.nivel,
          ca.nome AS cargo,
          ar.nome AS area,
          pu.apelido AS usuario,
          ch.horas_planej,
          ch.descricao,
          nvl(se.nome, 'ND') AS servico
     FROM contrato_horas   ch,
          cargo            ca,
          pessoa           pu,
          area             ar,
          contrato_servico cs,
          servico          se
    WHERE ch.contrato_id = p_contrato_id
      AND ch.cargo_id = ca.cargo_id(+)
      AND ch.usuario_id = pu.usuario_id(+)
      AND ch.area_id = ar.area_id(+)
      AND ch.contrato_servico_id = cs.contrato_servico_id(+)
      AND cs.servico_id = se.servico_id(+)
    ORDER BY 1,
             2,
             3,
             4,
             5;
  --
  -- horas alocadas
  CURSOR c_al IS
   SELECT ch.data,
          ch.nivel,
          ca.nome AS cargo,
          ar.nome AS area,
          ch.descricao,
          nvl(se.nome, 'ND') AS servico,
          pu.apelido AS usuario,
          hu.horas_aloc
     FROM contrato_horas_usu hu,
          contrato_horas     ch,
          cargo              ca,
          pessoa             pu,
          area               ar,
          contrato_servico   cs,
          servico            se
    WHERE ch.contrato_id = p_contrato_id
      AND ch.cargo_id = ca.cargo_id(+)
      AND ch.area_id = ar.area_id(+)
      AND ch.contrato_servico_id = cs.contrato_servico_id(+)
      AND cs.servico_id = se.servico_id(+)
      AND ch.contrato_horas_id = hu.contrato_horas_id
      AND hu.usuario_id = pu.usuario_id
    ORDER BY 1,
             2,
             3,
             4,
             5;
  --
  CURSOR c_us IS
   SELECT pe.apelido AS usuario
     FROM contrato_usuario cp,
          pessoa           pe
    WHERE cp.contrato_id = p_contrato_id
      AND cp.usuario_id = pe.usuario_id
    ORDER BY pe.apelido;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("contrato_id", co.contrato_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("num_contrato", to_char(co.numero)),
                   xmlelement("tipo_contrato", tc.nome),
                   xmlelement("nome", co.nome),
                   xmlelement("cod_ext_contrato", co.cod_ext_contrato),
                   xmlelement("status", co.status),
                   xmlelement("data_status", data_hora_mostrar(co.data_status)),
                   xmlelement("empresa_resp", pe.apelido),
                   xmlelement("solicitante", ps.apelido),
                   xmlelement("contratante", pc.apelido),
                   xmlelement("contato", ct.apelido),
                   xmlelement("contato_fatur", cf.apelido),
                   xmlelement("empresa_fatur", pf.apelido),
                   xmlelement("data_entrada", data_hora_mostrar(co.data_entrada)),
                   xmlelement("data_inicio", data_mostrar(co.data_inicio)),
                   xmlelement("data_termino", data_mostrar(co.data_termino)),
                   xmlelement("assinado", co.flag_assinado),
                   xmlelement("data_assinatura", data_mostrar(co.data_assinatura)),
                   xmlelement("renovavel", co.flag_renovavel),
                   xmlelement("contrato_fisico", co.flag_ctr_fisico),
                   xmlelement("pago_cliente", co.flag_pago_cliente),
                   xmlelement("tem_bloqeio_negoc", co.flag_bloq_negoc),
                   xmlelement("usa_bv_fornec", co.flag_bv_fornec),
                   xmlelement("perc_bv", numero_mostrar(co.perc_bv, 5, 'N')),
                   xmlelement("ordem_compra", co.ordem_compra),
                   xmlelement("cod_ext_ordem", co.cod_ext_ordem),
                   xmlelement("perc_desconto", numero_mostrar(co.perc_desc, 2, 'N')),
                   xmlelement("data_desconto", data_mostrar(co.data_desc)),
                   xmlelement("autor_desconto", pd.apelido))
    INTO v_xml
    FROM contrato      co,
         tipo_contrato tc,
         pessoa        pc,
         pessoa        pe,
         pessoa        pf,
         pessoa        ct,
         pessoa        cf,
         pessoa        ps,
         pessoa        pd
   WHERE co.contrato_id = p_contrato_id
     AND co.tipo_contrato_id = tc.tipo_contrato_id
     AND co.contratante_id = pc.pessoa_id
     AND co.emp_resp_id = pe.pessoa_id(+)
     AND co.emp_faturar_por_id = pf.pessoa_id(+)
     AND co.contato_id = ct.pessoa_id(+)
     AND co.contato_fatur_id = cf.pessoa_id(+)
     AND co.usuario_solic_id = ps.usuario_id(+)
     AND co.usuario_desc_id = pd.usuario_id(+);
  --
  ------------------------------------------------------------
  -- monta INFORMACOES FINANCEIRAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_na IN c_na
  LOOP
   SELECT xmlagg(xmlelement("info_finan",
                            xmlelement("codigo", r_na.codigo),
                            xmlelement("nome", r_na.nome),
                            xmlelement("tipo", r_na.mod_calculo),
                            xmlelement("valor_padrao", r_na.valor_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;

  END LOOP;
  --
  SELECT xmlagg(xmlelement("info_financeiras", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta SERVICOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_se IN c_se
  LOOP
   SELECT xmlagg(xmlelement("servico",
                            xmlelement("servico", r_se.nome_servico),
                            xmlelement("empresa_resp", r_se.empresa_resp),
                            xmlelement("valor_servico", r_se.valor_servico),
                            xmlelement("data_refer", r_se.data_refer),
                            xmlelement("usuario", r_se.usuario),
                            xmlelement("cod_externo", r_se.cod_externo)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;

  END LOOP;
  --
  SELECT xmlagg(xmlelement("servicos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta PARCELAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlagg(xmlelement("parcela",
                            xmlelement("servico", r_pa.servico),
                            xmlelement("num_parcela", r_pa.num_parcela),
                            xmlelement("data_parcela", r_pa.data_parcela),
                            xmlelement("valor_parcela", r_pa.valor_parcela),
                            xmlelement("status", r_pa.status)))
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
  -- monta ENDERECADOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_us IN c_us
  LOOP
   SELECT xmlagg(xmlelement("enderecado", xmlelement("usuario", r_us.usuario)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;

  END LOOP;
  --
  SELECT xmlagg(xmlelement("enderecados", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta ESTIMATIVA_HORAS (horas planejadas)
  ------------------------------------------------------------
  -- valores encriptados nao foram gravados no XML
  -- para manter a seguranca da informacao.
  v_xml_aux1 := NULL;
  FOR r_ho IN c_ho
  LOOP
   SELECT xmlagg(xmlelement("estimativa",
                            xmlelement("servico", r_ho.servico),
                            xmlelement("data", to_char(r_ho.data, 'MM/YYYY')),
                            xmlelement("cargo", r_ho.cargo),
                            xmlelement("nivel", r_ho.nivel),
                            xmlelement("area", r_ho.area),
                            xmlelement("usuario", r_ho.usuario),
                            xmlelement("horas",
                                       numero_mostrar(r_ho.horas_planej, 2, 'N'),
                                       xmlelement("descricao", r_ho.descricao))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;

  END LOOP;
  --
  SELECT xmlagg(xmlelement("estimativa_horas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta ALOCACAO_HORAS (horas alocadas)
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_al IN c_al
  LOOP
   SELECT xmlagg(xmlelement("alocacao",
                            xmlelement("servico", r_al.servico),
                            xmlelement("data", to_char(r_al.data, 'MM/YYYY')),
                            xmlelement("cargo", r_al.cargo),
                            xmlelement("nivel", r_al.nivel),
                            xmlelement("area", r_al.area),
                            xmlelement("usuario", r_al.usuario),
                            xmlelement("horas", numero_mostrar(r_al.horas_aloc, 2, 'N'))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;

  END LOOP;
  --
  SELECT xmlagg(xmlelement("alocacao_horas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "contrato"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("contrato", v_xml))
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
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/09/2018
  -- DESCRICAO: retorna o numero formatado de um contrato.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_contrato_id IN contrato.contrato_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno         VARCHAR2(100);
  v_qt              INTEGER;
  v_numero_contrato contrato.numero%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT numero
    INTO v_numero_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  IF length(v_numero_contrato) <= 4 THEN
   v_retorno := 'CT-' || TRIM(to_char(v_numero_contrato, '0000'));
  ELSE
   v_retorno := 'CT-' || TRIM(to_char(v_numero_contrato));
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_formatar;
 --
 --
 FUNCTION horas_do_usuario_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 25/06/2022
  -- DESCRICAO: retorna horas mensais de um determinado usuario relacionadas a
  --   alocacao em conratos, de acordo com o tipo especificado.
  --     PROD - horas mensais produtivas do usuario
  --     ALOC - horas mensais alocadas em contratos
  --     DISP - horas mensais livres/disponiveis do usuario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id IN contrato.empresa_id%TYPE,
  p_usuario_id IN contrato.contrato_id%TYPE,
  p_tipo       IN VARCHAR2
 ) RETURN NUMBER AS

  v_qt                INTEGER;
  v_retorno           NUMBER;
  v_exception         EXCEPTION;
  v_saida             EXCEPTION;
  v_horas_aloc        NUMBER;
  v_horas_mes         NUMBER;
  v_horas_diarias_usu NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  ------------------------------------------------------------
  -- consistencias/preparacao
  ------------------------------------------------------------
  IF p_tipo NOT IN ('ALOC', 'DISP', 'PROD') OR TRIM(p_tipo) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(num_horas_prod_dia, 0)
    INTO v_horas_diarias_usu
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_horas_diarias_usu = 0 THEN
   v_horas_diarias_usu := nvl(numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                              'NUM_HORAS_PRODUTIVAS')),
                              0);
  END IF;
  --
  ------------------------------------------------------------
  -- calculos
  ------------------------------------------------------------
  IF p_tipo IN ('ALOC', 'DISP') THEN
   SELECT nvl(SUM(hu.horas_aloc), 0)
     INTO v_horas_aloc
     FROM contrato_horas_usu hu,
          contrato_horas     ch,
          contrato           ct
    WHERE ct.empresa_id = p_empresa_id
      AND ct.contrato_id = ch.contrato_id
      AND ch.contrato_horas_id = hu.contrato_horas_id
      AND hu.usuario_id = p_usuario_id;

  END IF;
  --
  IF p_tipo = 'ALOC' THEN
   v_retorno := v_horas_aloc;
  ELSIF p_tipo = 'DISP' THEN
   v_retorno := v_horas_diarias_usu * 22 - v_horas_aloc;
  ELSIF p_tipo = 'PROD' THEN
   v_retorno := v_horas_diarias_usu * 22;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END horas_do_usuario_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: retorna o valor de um determinado contrato, de acordo com o tipo
  --  especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_contrato_id IN contrato.contrato_id%TYPE,
  p_tipo_valor  IN VARCHAR2
 ) RETURN NUMBER AS

  v_qt             INTEGER;
  v_retorno        NUMBER;
  v_exception      EXCEPTION;
  v_saida          EXCEPTION;
  v_valor_faturado NUMBER;
  v_valor_abatido  NUMBER;
  v_valor_afaturar NUMBER;
  v_valor_alocado  NUMBER;
  v_valor_aalocar  NUMBER;
  v_valor_total    NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  v_valor_faturado := 0;
  v_valor_afaturar := 0;
  v_valor_abatido  := 0;
  --
  ------------------------------------------------------------
  -- preparacao dos calculos
  ------------------------------------------------------------
  IF p_tipo_valor NOT IN ('TOTAL', 'FATURADO', 'AFATURAR', 'ABATIDO', 'ALOCADO', 'AALOCAR') OR
     TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor TOTAL
  ------------------------------------------------------------
  IF p_tipo_valor = 'TOTAL' THEN
   SELECT nvl(SUM(valor_parcela), 0)
     INTO v_valor_total
     FROM parcela_contrato
    WHERE contrato_id = p_contrato_id;
   --
   v_retorno := v_valor_total;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor ABATIDO
  ------------------------------------------------------------
  IF p_tipo_valor = 'ABATIDO' THEN
   SELECT nvl(SUM(ab.valor_abat), 0)
     INTO v_valor_abatido
     FROM abatimento_ctr   ab,
          parcela_contrato pa
    WHERE ab.parcela_contrato_id = pa.parcela_contrato_id
      AND pa.contrato_id = p_contrato_id;
   --
   v_retorno := v_valor_abatido;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor FATURADO
  ------------------------------------------------------------
  IF p_tipo_valor = 'FATURADO' THEN
   SELECT nvl(SUM(pf.valor_fatura), 0)
     INTO v_valor_faturado
     FROM parcela_fatur_ctr pf,
          parcela_contrato  pa
    WHERE pf.parcela_contrato_id = pa.parcela_contrato_id
      AND pa.contrato_id = p_contrato_id;
   --
   v_retorno := v_valor_faturado;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor AFATURAR
  ------------------------------------------------------------
  IF p_tipo_valor = 'AFATURAR' THEN
   SELECT nvl(SUM(valor_parcela), 0)
     INTO v_valor_total
     FROM parcela_contrato
    WHERE contrato_id = p_contrato_id;
   --
   v_valor_faturado := contrato_pkg.valor_retornar(p_contrato_id, 'FATURADO');
   v_valor_abatido  := contrato_pkg.valor_retornar(p_contrato_id, 'ABATIDO');
   --
   v_retorno := v_valor_total - v_valor_faturado - v_valor_abatido;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor ALOCADO
  ------------------------------------------------------------
  IF p_tipo_valor = 'ALOCADO' THEN
   SELECT nvl(SUM(valor_alocado), 0)
     INTO v_valor_alocado
     FROM job_receita_ctr
    WHERE contrato_id = p_contrato_id;
   --
   v_retorno := v_valor_alocado;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor AALOCAR
  ------------------------------------------------------------
  IF p_tipo_valor = 'AALOCAR' THEN
   v_valor_total   := contrato_pkg.valor_retornar(p_contrato_id, 'TOTAL');
   v_valor_alocado := contrato_pkg.valor_retornar(p_contrato_id, 'ALOCADO');
   v_valor_abatido := contrato_pkg.valor_retornar(p_contrato_id, 'ABATIDO');
   --
   v_retorno := v_valor_total - v_valor_alocado - v_valor_abatido;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION valor_parcela_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: retorna o valor de uma determinada parcela, de acordo com o tipo
  --  especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_tipo_valor          IN VARCHAR2
 ) RETURN NUMBER AS

  v_qt             INTEGER;
  v_retorno        NUMBER;
  v_exception      EXCEPTION;
  v_saida          EXCEPTION;
  v_valor_faturado NUMBER;
  v_valor_abatido  NUMBER;
  v_valor_afaturar NUMBER;
  v_valor_parcela  NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  v_valor_faturado := 0;
  v_valor_afaturar := 0;
  v_valor_abatido  := 0;
  --
  ------------------------------------------------------------
  -- preparacao dos calculos
  ------------------------------------------------------------
  IF p_tipo_valor NOT IN ('FATURADO', 'AFATURAR', 'ABATIDO') OR TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula valor ABATIDO
  ------------------------------------------------------------
  IF p_tipo_valor = 'ABATIDO' THEN
   SELECT nvl(SUM(valor_abat), 0)
     INTO v_valor_abatido
     FROM abatimento_ctr
    WHERE parcela_contrato_id = p_parcela_contrato_id;
   --
   v_retorno := v_valor_abatido;
  END IF; -- fim do ABATIDO
  --
  ------------------------------------------------------------
  -- calcula valor FATURADO
  ------------------------------------------------------------
  IF p_tipo_valor = 'FATURADO' THEN
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_faturado
     FROM parcela_fatur_ctr
    WHERE parcela_contrato_id = p_parcela_contrato_id;
   --
   v_retorno := v_valor_faturado;
  END IF; -- fim do FATURADO
  --
  ------------------------------------------------------------
  -- calcula valor AFATURAR
  ------------------------------------------------------------
  IF p_tipo_valor = 'AFATURAR' THEN
   SELECT valor_parcela
     INTO v_valor_parcela
     FROM parcela_contrato
    WHERE parcela_contrato_id = p_parcela_contrato_id;
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_faturado
     FROM parcela_fatur_ctr
    WHERE parcela_contrato_id = p_parcela_contrato_id;
   --
   SELECT nvl(SUM(valor_abat), 0)
     INTO v_valor_abatido
     FROM abatimento_ctr
    WHERE parcela_contrato_id = p_parcela_contrato_id;
   --
   v_retorno := v_valor_parcela - v_valor_faturado - v_valor_abatido;
  END IF; -- fim do AFATURAR
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_parcela_retornar;
 --
 --
 FUNCTION status_parcela_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: retorna o status de uma determinada parcela.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE
 ) RETURN VARCHAR2 AS

  v_qt             INTEGER;
  v_retorno        VARCHAR2(50);
  v_exception      EXCEPTION;
  v_saida          EXCEPTION;
  v_valor_faturado NUMBER;
  v_valor_afaturar NUMBER;
  v_valor_parcela  NUMBER;
  --
 BEGIN
  v_retorno := NULL;
  --
  v_valor_faturado := 0;
  v_valor_afaturar := 0;
  --
  ------------------------------------------------------------
  -- preparacao dos calculos
  ------------------------------------------------------------
  SELECT valor_parcela
    INTO v_valor_parcela
    FROM parcela_contrato
   WHERE parcela_contrato_id = p_parcela_contrato_id;
  --
  v_valor_faturado := contrato_pkg.valor_parcela_retornar(p_parcela_contrato_id, 'FATURADO');
  v_valor_afaturar := contrato_pkg.valor_parcela_retornar(p_parcela_contrato_id, 'AFATURAR');
  --
  IF v_valor_afaturar = v_valor_parcela THEN
   v_retorno := 'PEND';
  ELSIF v_valor_afaturar = 0 THEN
   v_retorno := 'FATU';
  ELSE
   v_retorno := 'PARC';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END status_parcela_retornar;
 --
--
END; -- CONTRATO_PKG


/
