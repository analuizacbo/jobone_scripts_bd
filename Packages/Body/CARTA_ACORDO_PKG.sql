--------------------------------------------------------
--  DDL for Package Body CARTA_ACORDO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CARTA_ACORDO_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/04/2007
  -- DESCRICAO: Inclusão de CARTA_ACORDO sem produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta multi-item.
  -- Silvia            29/02/2008  Tipo de faturamento do BV (novo valor 'NA')
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            16/03/2009  Novos campos em carta acordo (perc padrao, contato).
  -- Silvia            27/03/2009  Zera imposto do fornecedor qdo nao faz sentido
  -- Silvia            29/05/2009  Consiste bloqueio da negociacao
  -- Silvia            08/02/2011  Novo parametro flag_mostrar_ac.
  -- Silvia            25/02/2014  Parametro contato fornecedor passou a aceitar ID ou string
  -- Silvia            23/05/2014  Registro do elaborador.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  -- Silvia            25/11/2014  Verificacao da existencia de usuario aprovador
  -- Silvia            17/12/2014  Grava na item_carta: qtq,freq,custo unit,tipo prod,compl
  -- Silvia            04/02/2015  Novo parametro flag_com_aprovacao
  -- Silvia            27/03/2015  Novo atributo flag_com_prodcomp
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            13/07/2015  Novo parametro de justificativa fornec nao homologado.
  --                               Instanciacao de dados do fornecedor.
  -- Silvia            09/09/2015  Controle de aceitacao.
  -- Silvia            04/05/2016  Guarda numero formatado da carta acordo.
  -- Silvia            07/05/2018  Guarda empresa_id na carta acordo
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Ana Luiza         06/08/2028  Tratativa para voltar o ultimo registro da tab pessoa_homolog
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_fornecedor_id          IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id             IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id     IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec         IN carta_acordo.contato_fornec%TYPE,
  p_jus_fornec_naohmlg     IN VARCHAR2,
  p_desc_item              IN VARCHAR2,
  p_valor_credito          IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_motivo_atu_bv          IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_motivo_atu_imp         IN VARCHAR2,
  p_tipo_fatur_bv          IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_condicao_pagto_id      IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto             IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id        IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia        IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta          IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta         IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar     IN VARCHAR2,
  p_instr_especiais        IN VARCHAR2,
  p_entre_data_prototipo   IN VARCHAR2,
  p_entre_data_produto     IN VARCHAR2,
  p_entre_local            IN VARCHAR2,
  p_monta_hora_ini         IN VARCHAR2,
  p_monta_data_ini         IN VARCHAR2,
  p_monta_hora_fim         IN VARCHAR2,
  p_monta_data_fim         IN VARCHAR2,
  p_pserv_hora_ini         IN VARCHAR2,
  p_pserv_data_ini         IN VARCHAR2,
  p_pserv_hora_fim         IN VARCHAR2,
  p_pserv_data_fim         IN VARCHAR2,
  p_desmo_hora_ini         IN VARCHAR2,
  p_desmo_data_ini         IN VARCHAR2,
  p_desmo_hora_fim         IN VARCHAR2,
  p_desmo_data_fim         IN VARCHAR2,
  p_event_desc             IN VARCHAR2,
  p_event_local            IN VARCHAR2,
  p_event_hora_ini         IN VARCHAR2,
  p_event_data_ini         IN VARCHAR2,
  p_event_hora_fim         IN VARCHAR2,
  p_event_data_fim         IN VARCHAR2,
  p_produtor_id            IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao     IN VARCHAR2,
  p_cod_ext_carta          IN VARCHAR2,
  p_carta_acordo_id        OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_num_job                job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_flag_bloq_negoc        job.flag_bloq_negoc%TYPE;
  v_orcamento_id           item.orcamento_id%TYPE;
  v_item_id                item.item_id%TYPE;
  v_valor_aprovado_it      item.valor_aprovado%TYPE;
  v_tipo_produto_id        item.tipo_produto_id%TYPE;
  v_complemento            item.complemento%TYPE;
  v_tipo_item_ori          VARCHAR2(10);
  v_tipo_item              VARCHAR2(10);
  v_tipo_item_ant          VARCHAR2(10);
  v_flag_pago_cliente      item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant  item.flag_pago_cliente%TYPE;
  v_nome_item              VARCHAR2(200);
  v_carta_acordo_id        carta_acordo.carta_acordo_id%TYPE;
  v_num_carta_formatado    carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado         carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor       carta_acordo.valor_fornecedor%TYPE;
  v_valor_aprovado_ca      carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca    carta_acordo.valor_fornecedor%TYPE;
  v_valor_credito          carta_acordo.valor_credito_usado%TYPE;
  v_perc_bv                carta_acordo.perc_bv%TYPE;
  v_perc_imposto           carta_acordo.perc_imposto%TYPE;
  v_num_carta_acordo       carta_acordo.num_carta_acordo%TYPE;
  v_tipo_fatur_bv          carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr            carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr       carta_acordo.perc_imposto_pdr%TYPE;
  v_flag_mostrar_ac        carta_acordo.flag_mostrar_ac%TYPE;
  v_contato_fornec_id      carta_acordo.contato_fornec_id%TYPE;
  v_contato_fornec         carta_acordo.contato_fornec%TYPE;
  v_status_aceite          carta_acordo.status_aceite%TYPE;
  v_operador               lancamento.operador%TYPE;
  v_descricao              lancamento.descricao%TYPE;
  v_fornecedor             pessoa.apelido%TYPE;
  v_flag_fornec_homolog    CHAR(1);
  v_nivel_excelencia       NUMBER(5, 2);
  v_nivel_parceria         NUMBER(5, 2);
  v_delimitador            CHAR(1);
  v_vetor_parc_datas       LONG;
  v_vetor_parc_valores     LONG;
  v_vetor_parc_num_dias    LONG;
  v_vetor_item_id          LONG;
  v_vetor_valor_aprovado   LONG;
  v_vetor_valor_fornecedor LONG;
  v_data_parcela_char      VARCHAR2(20);
  v_valor_parcela_char     VARCHAR2(20);
  v_num_dias_char          VARCHAR2(20);
  v_valor_aprovado_char    VARCHAR2(20);
  v_valor_fornecedor_char  VARCHAR2(20);
  v_data_parcela           parcela_carta.data_parcela%TYPE;
  v_valor_parcela          parcela_carta.valor_parcela%TYPE;
  v_num_dias               parcela_carta.num_dias%TYPE;
  v_num_dias_ant           parcela_carta.num_dias%TYPE;
  v_parcela_carta_id       parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela            parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant       parcela_carta.data_parcela%TYPE;
  v_valor_acumulado        NUMBER;
  v_tipo_data              VARCHAR2(10);
  v_tipo_data_ant          VARCHAR2(10);
  v_xml_doc                VARCHAR2(100);
  v_xml_entrega            xmltype;
  v_xml_montagem           xmltype;
  v_xml_prest_servico      xmltype;
  v_xml_desmontagem        xmltype;
  v_xml_evento             xmltype;
  v_xml_corpo              xmltype;
  v_xml_carta              VARCHAR2(4000);
  v_valor_disponivel       NUMBER;
  v_valor_liberado_b       NUMBER;
  v_lbl_job                VARCHAR2(100);
  v_flag_bv_faturar        VARCHAR2(20);
  v_flag_bv_abater         VARCHAR2(20);
  v_flag_bv_creditar       VARCHAR2(20);
  v_flag_bv_permutar       VARCHAR2(20);
  v_flag_pgto_manual       VARCHAR2(20);
  v_flag_pgto_tabela       VARCHAR2(20);
  v_flag_com_forma_pag     VARCHAR2(20);
  v_flag_justificar        VARCHAR2(20);
  v_flag_com_aceite        VARCHAR2(20);
  v_local_parcelam_fornec  VARCHAR2(50);
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  --
 BEGIN
  v_qt                    := 0;
  p_carta_acordo_id       := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_flag_justificar       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'JUSTIFICAR_FORNEC_NAOHMLG');
  v_flag_com_aceite       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'CA_HABILITA_ACEITE_FORNEC');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.flag_bloq_negoc
    INTO v_num_job,
         v_status_job,
         v_flag_bloq_negoc
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_com_aceite = 'S'
  THEN
   v_status_aceite := 'PEND';
  ELSE
   v_status_aceite := 'NA';
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(nvl(TRIM(p_contato_fornec), '0')) = 1
  THEN
   -- veio contato nulo ou inteiro
   v_contato_fornec_id := to_number(nvl(TRIM(p_contato_fornec), '0'));
   --
   IF v_contato_fornec_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao
    WHERE pessoa_filho_id = v_contato_fornec_id
      AND pessoa_pai_id = p_fornecedor_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
    RAISE v_exception;
   END IF;
   --
   SELECT apelido
     INTO v_contato_fornec
     FROM pessoa
    WHERE pessoa_id = v_contato_fornec_id;
  
  ELSE
   -- veio o nome do contato
   v_contato_fornec    := TRIM(p_contato_fornec);
   v_contato_fornec_id := NULL;
  END IF;
  --
  SELECT p.apelido,
         nvl(ph.perc_bv, 0),
         nvl(ph.perc_imposto, 0),
         decode(ph.status_para, 'NAPL', 'S', 'HMLG', 'S', 'N'),
         p.nivel_qualidade,
         p.nivel_parceria
    INTO v_fornecedor,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_flag_fornec_homolog,
         v_nivel_excelencia,
         v_nivel_parceria
    FROM pessoa p
    LEFT JOIN pessoa_homolog ph
      ON p.pessoa_id = ph.pessoa_id
   WHERE p.pessoa_id = p_fornecedor_id
     AND ph.flag_atual = 'S'
     AND ph.data_hora = (SELECT MAX(data_hora)
                           FROM pessoa_homolog
                          WHERE pessoa_id = p_fornecedor_id); --ALCBO_060825;
  --
  IF v_flag_fornec_homolog = 'N' AND v_flag_justificar = 'S' AND TRIM(p_jus_fornec_naohmlg) IS NULL
  
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado deve ser informada.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_jus_fornec_naohmlg) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado ' ||
                 'não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_aprovacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_carta_acordo.nextval
    INTO v_carta_acordo_id
    FROM dual;
  --
  v_flag_mostrar_ac := 'S';
  --
  SELECT nvl(MAX(num_carta_acordo), 0) + 1
    INTO v_num_carta_acordo
    FROM carta_acordo
   WHERE job_id = p_job_id;
  --
  INSERT INTO carta_acordo
   (carta_acordo_id,
    empresa_id,
    job_id,
    num_carta_acordo,
    data_criacao,
    fornecedor_id,
    contato_fornec,
    contato_fornec_id,
    cliente_id,
    emp_faturar_por_id,
    flag_mostrar_ac,
    desc_item,
    instr_especiais,
    valor_aprovado,
    valor_fornecedor,
    perc_bv,
    perc_bv_pdr,
    motivo_atu_bv,
    perc_imposto,
    perc_imposto_pdr,
    motivo_atu_imp,
    tipo_fatur_bv,
    status,
    produtor_id,
    texto_xml,
    condicao_pagto_id,
    modo_pagto,
    fi_banco_fornec_id,
    num_agencia,
    num_conta,
    tipo_conta,
    valor_credito_usado,
    elaborador_id,
    flag_com_aprov,
    flag_com_prodcomp,
    flag_fornec_homolog,
    jus_fornec_naohmlg,
    nivel_excelencia,
    nivel_parceria,
    status_aceite,
    cod_ext_carta)
  VALUES
   (v_carta_acordo_id,
    p_empresa_id,
    p_job_id,
    v_num_carta_acordo,
    SYSDATE,
    p_fornecedor_id,
    v_contato_fornec,
    v_contato_fornec_id,
    p_cliente_id,
    p_emp_faturar_por_id,
    v_flag_mostrar_ac,
    TRIM(p_desc_item),
    TRIM(p_instr_especiais),
    0,
    0,
    v_perc_bv,
    v_perc_bv_pdr,
    TRIM(p_motivo_atu_bv),
    v_perc_imposto,
    v_perc_imposto_pdr,
    TRIM(p_motivo_atu_imp),
    v_tipo_fatur_bv,
    'EMAPRO',
    p_produtor_id,
    v_xml_carta,
    zvl(p_condicao_pagto_id, NULL),
    TRIM(p_modo_pagto),
    zvl(p_emp_fi_banco_id, NULL),
    TRIM(p_emp_num_agencia),
    TRIM(p_emp_num_conta),
    TRIM(p_emp_tipo_conta),
    v_valor_credito,
    p_usuario_sessao_id,
    p_flag_com_aprovacao,
    'N',
    v_flag_fornec_homolog,
    TRIM(p_jus_fornec_naohmlg),
    v_nivel_excelencia,
    v_nivel_parceria,
    v_status_aceite,
    TRIM(p_cod_ext_carta));
  --
  v_num_carta_formatado := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
  --
  UPDATE carta_acordo
     SET num_carta_formatado = v_num_carta_formatado
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_tipo_item_ant         := NULL;
  v_flag_pago_cliente_ant := NULL;
  --
  v_delimitador         := '|';
  v_valor_aprovado_ca   := 0;
  v_valor_fornecedor_ca := 0;
  --
  v_vetor_item_id          := p_vetor_item_id;
  v_vetor_valor_aprovado   := p_vetor_valor_aprovado;
  v_vetor_valor_fornecedor := p_vetor_valor_fornecedor;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id               := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_aprovado_char   := prox_valor_retornar(v_vetor_valor_aprovado, v_delimitador);
   v_valor_fornecedor_char := prox_valor_retornar(v_vetor_valor_fornecedor, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item      it,
          orcamento oc
    WHERE it.item_id = v_item_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe ou não pertence a esse ' || v_lbl_job || ' (' ||
                  to_char(v_item_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_item,
          flag_pago_cliente,
          tipo_produto_id,
          complemento,
          orcamento_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_tipo_item,
          v_tipo_item_ori,
          v_flag_pago_cliente,
          v_tipo_produto_id,
          v_complemento,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma carta acordo com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido (' ||
                  v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma carta acordo.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_valor_aprovado_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor aprovado inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_fornecedor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_aprovado   := nvl(moeda_converter(v_valor_aprovado_char), 0);
   v_valor_fornecedor := nvl(moeda_converter(v_valor_fornecedor_char), 0);
   --
   IF v_valor_aprovado < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor aprovado inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ori = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                   moeda_mostrar(v_valor_aprovado, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_aprovado > v_valor_disponivel
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > 0 OR v_valor_fornecedor > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_carta
     WHERE carta_acordo_id = v_carta_acordo_id
       AND item_id = v_item_id;
    --
    IF v_qt > 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O item ' || v_nome_item ||
                   ', não pode ser lançado na carta acordo mais de uma vez.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO item_carta
     (item_carta_id,
      carta_acordo_id,
      item_id,
      valor_aprovado,
      valor_fornecedor,
      quantidade,
      frequencia,
      custo_unitario,
      tipo_produto_id,
      complemento)
    VALUES
     (seq_item_carta.nextval,
      v_carta_acordo_id,
      v_item_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      1,
      1,
      v_valor_fornecedor,
      v_tipo_produto_id,
      v_complemento);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    v_valor_aprovado_ca   := v_valor_aprovado_ca + v_valor_aprovado;
    v_valor_fornecedor_ca := v_valor_fornecedor_ca + v_valor_fornecedor;
   END IF;
   --
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais e atualizacao da carta acordo
  ------------------------------------------------------------
  --
  IF v_valor_aprovado_ca = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor foi informado para os itens dessa carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo total do fornecedor (' || moeda_mostrar(v_valor_fornecedor_ca, 'S') ||
                 ') não pode ser maior que o valor total aprovado pelo cliente (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF TRIM(p_perc_imposto) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   UPDATE carta_acordo
      SET perc_imposto = 0
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
    INTO v_flag_pago_cliente
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = v_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_flag_mostrar_ac := 'N';
  ELSE
   v_flag_mostrar_ac := 'S';
  END IF;
  --
  UPDATE carta_acordo
     SET valor_aprovado   = v_valor_aprovado_ca,
         valor_fornecedor = v_valor_fornecedor_ca,
         flag_mostrar_ac  = v_flag_mostrar_ac
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       v_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito > 0
  THEN
   -- a agencia usa o credito junto ao fornecedor (movimento de saida)
   v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' || v_num_carta_formatado;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     p_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_credito,
     'S',
     v_operador,
     NULL);
  
  END IF;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, p_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
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
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(v_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_carta_acordo_id,
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
  p_carta_acordo_id := v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- verificacao da existencia de usuario aprovador
  ------------------------------------------------------------
  IF p_flag_com_aprovacao = 'S' AND
     carta_acordo_pkg.usuario_aprov_verificar(p_empresa_id, v_carta_acordo_id) = 0
  THEN
   p_erro_cod := '10000';
   p_erro_msg := 'Não há nenhum Aprovador configurado para aprovar esta AO. A AO será enviada mesmo assim.';
  ELSE
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  END IF;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de carta acordo já existe (' || v_num_carta_formatado ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE monojob_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/10/2013
  -- DESCRICAO: Inclusão de CARTA_ACORDO monojob com produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/02/2015  Novo parametro flag_com_aprovacao
  -- Silvia            27/03/2015  Novo atributo flag_com_prodcomp
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            13/07/2015  Novo parametro de justificativa fornec nao homologado.
  --                               Instanciacao de dados do fornecedor.
  -- Silvia            09/09/2015  Controle de aceitacao.
  -- Silvia            30/09/2015  Registro do elaborador.
  -- Silvia            04/05/2016  Guarda numero formatado da carta acordo.
  -- Silvia            07/05/2018  Guarda empresa_id na carta acordo
  -- Silvia            18/06/2018  Novo parametro produto_fiscal_id.
  -- Silvia            30/07/2018  Consistencia de totais aprovados x qtd*freq*unitario
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Silvia            29/09/2020  Indicacao de sobras
  -- Ana Luiza         23/05/2024  Adicionado verificacao de privilegio
  -- Ana Luiza         08/04/2025  Trativa para so verificar valores se flag_pago_cliente = 'S'
  -- Ana Luiza         06/08/2028  Tratativa para voltar o ultimo registro da tab pessoa_homolog
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_job_id                  IN job.job_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_jus_fornec_naohmlg      IN VARCHAR2,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_valor_fornecedor  IN VARCHAR2,
  p_vetor_valor_aprovado    IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao      IN VARCHAR2,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_carta_acordo_id         OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_job_id                  job.job_id%TYPE;
  v_num_job                 job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_flag_bloq_negoc         job.flag_bloq_negoc%TYPE;
  v_orcamento_id            item.orcamento_id%TYPE;
  v_item_id                 item.item_id%TYPE;
  v_valor_aprovado_it       item.valor_aprovado%TYPE;
  v_tipo_item_ori           VARCHAR2(10);
  v_tipo_item               VARCHAR2(10);
  v_tipo_item_ant           VARCHAR2(10);
  v_flag_pago_cliente       item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant   item.flag_pago_cliente%TYPE;
  v_nome_item               VARCHAR2(200);
  v_carta_acordo_id         carta_acordo.carta_acordo_id%TYPE;
  v_num_carta_formatado     carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado          carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor        carta_acordo.valor_fornecedor%TYPE;
  v_valor_fornec_aux        carta_acordo.valor_fornecedor%TYPE;
  v_valor_aprovado_ca       carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca     carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv                 carta_acordo.perc_bv%TYPE;
  v_perc_imposto            carta_acordo.perc_imposto%TYPE;
  v_num_carta_acordo        carta_acordo.num_carta_acordo%TYPE;
  v_tipo_fatur_bv           carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr             carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr        carta_acordo.perc_imposto_pdr%TYPE;
  v_flag_mostrar_ac         carta_acordo.flag_mostrar_ac%TYPE;
  v_valor_credito           carta_acordo.valor_credito_usado%TYPE;
  v_contato_fornec          carta_acordo.contato_fornec%TYPE;
  v_status_aceite           carta_acordo.status_aceite%TYPE;
  v_operador                lancamento.operador%TYPE;
  v_descricao               lancamento.descricao%TYPE;
  v_fornecedor              pessoa.apelido%TYPE;
  v_flag_fornec_homolog     CHAR(1);
  v_nivel_excelencia        NUMBER(5, 2);
  v_nivel_parceria          NUMBER(5, 2);
  v_tipo_produto_id         tipo_produto.tipo_produto_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_parc_datas        LONG;
  v_vetor_parc_valores      LONG;
  v_vetor_parc_num_dias     LONG;
  v_vetor_item_id           LONG;
  v_vetor_tipo_produto_id   LONG;
  v_vetor_produto_fiscal_id LONG;
  v_vetor_quantidade        LONG;
  v_vetor_frequencia        LONG;
  v_vetor_custo_unitario    LONG;
  v_vetor_complemento       LONG;
  v_vetor_valor_aprovado    LONG;
  v_vetor_valor_fornecedor  LONG;
  v_vetor_sobra_valores     LONG;
  v_vetor_sobra_item_id     LONG;
  v_data_parcela_char       VARCHAR2(50);
  v_valor_parcela_char      VARCHAR2(50);
  v_num_dias_char           VARCHAR2(50);
  v_quantidade_char         VARCHAR2(50);
  v_frequencia_char         VARCHAR2(50);
  v_valor_aprovado_char     VARCHAR2(50);
  v_valor_fornecedor_char   VARCHAR2(50);
  v_custo_unitario_char     VARCHAR2(50);
  v_valor_sobra_char        VARCHAR2(50);
  v_complemento             VARCHAR2(32000);
  v_sobra_id                sobra.sobra_id%TYPE;
  v_valor_sobra             item_sobra.valor_sobra_item%TYPE;
  v_quantidade              item_carta.quantidade%TYPE;
  v_frequencia              item_carta.frequencia%TYPE;
  v_custo_unitario          item_carta.custo_unitario%TYPE;
  v_produto_fiscal_id       item_carta.produto_fiscal_id%TYPE;
  v_data_parcela            parcela_carta.data_parcela%TYPE;
  v_valor_parcela           parcela_carta.valor_parcela%TYPE;
  v_num_dias                parcela_carta.num_dias%TYPE;
  v_num_dias_ant            parcela_carta.num_dias%TYPE;
  v_parcela_carta_id        parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela             parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant        parcela_carta.data_parcela%TYPE;
  v_valor_acumulado         NUMBER;
  v_tipo_data               VARCHAR2(10);
  v_tipo_data_ant           VARCHAR2(10);
  v_xml_doc                 VARCHAR2(100);
  v_xml_entrega             xmltype;
  v_xml_montagem            xmltype;
  v_xml_prest_servico       xmltype;
  v_xml_desmontagem         xmltype;
  v_xml_evento              xmltype;
  v_xml_corpo               xmltype;
  v_xml_carta               VARCHAR2(4000);
  v_valor_disponivel        NUMBER;
  v_valor_liberado_b        NUMBER;
  v_lbl_job                 VARCHAR2(100);
  v_flag_bv_faturar         VARCHAR2(20);
  v_flag_bv_abater          VARCHAR2(20);
  v_flag_bv_creditar        VARCHAR2(20);
  v_flag_bv_permutar        VARCHAR2(20);
  v_flag_pgto_manual        VARCHAR2(20);
  v_flag_pgto_tabela        VARCHAR2(20);
  v_flag_com_forma_pag      VARCHAR2(20);
  v_flag_justificar         VARCHAR2(20);
  v_flag_com_aceite         VARCHAR2(20);
  v_flag_prod_fiscal        VARCHAR2(20);
  v_local_parcelam_fornec   VARCHAR2(50);
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  --
  -- cursor para consistir totais aprovados x qtd*freq*unitario
  -- (apenas o primeiro registro encontrado)
  CURSOR c_va IS
   SELECT TRIM(v.nome || ' ' || v.complemento) AS produto,
          v.valor_calculado,
          v.valor_lancado
     FROM (SELECT tp.nome,
                  ic.complemento,
                  nvl(round(ic.quantidade * ic.frequencia * ic.custo_unitario, 2), 0) AS valor_calculado,
                  nvl(SUM(ic.valor_aprovado), 0) AS valor_lancado
             FROM item_carta   ic,
                  tipo_produto tp
            WHERE ic.carta_acordo_id = v_carta_acordo_id
              AND ic.tipo_produto_id = tp.tipo_produto_id
            GROUP BY ic.tipo_produto_id,
                     tp.nome,
                     ic.complemento,
                     ic.quantidade,
                     ic.frequencia,
                     ic.custo_unitario,
                     nvl(ic.produto_fiscal_id, 0)
           HAVING nvl(round(ic.quantidade * ic.frequencia * ic.custo_unitario, 2), 0) <> nvl(SUM(ic.valor_aprovado), 0)) v
    WHERE rownum = 1;
  --
 BEGIN
  v_qt                    := 0;
  p_carta_acordo_id       := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_flag_justificar       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'JUSTIFICAR_FORNEC_NAOHMLG');
  v_flag_com_aceite       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'CA_HABILITA_ACEITE_FORNEC');
  v_flag_prod_fiscal      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COM_PRODUTO_FISCAL');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.flag_bloq_negoc
    INTO v_num_job,
         v_status_job,
         v_flag_bloq_negoc
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_com_aceite = 'S'
  THEN
   v_status_aceite := 'PEND';
  ELSE
   v_status_aceite := 'NA';
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT p.apelido,
         nvl(ph.perc_bv, 0),
         nvl(ph.perc_imposto, 0),
         decode(ph.status_para, 'NAPL', 'S', 'HMLG', 'S', 'N'),
         p.nivel_qualidade,
         p.nivel_parceria
    INTO v_fornecedor,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_flag_fornec_homolog,
         v_nivel_excelencia,
         v_nivel_parceria
    FROM pessoa p
    LEFT JOIN pessoa_homolog ph
      ON p.pessoa_id = ph.pessoa_id
   WHERE p.pessoa_id = p_fornecedor_id
     AND ph.flag_atual = 'S'
     AND ph.data_hora = (SELECT MAX(data_hora)
                           FROM pessoa_homolog
                          WHERE pessoa_id = p_fornecedor_id); --ALCBO_060825
  --
  IF v_flag_fornec_homolog = 'N' AND v_flag_justificar = 'S' AND TRIM(p_jus_fornec_naohmlg) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado deve ser informada.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_jus_fornec_naohmlg) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado ' ||
                 'não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_fornec_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_filho_id = p_contato_fornec_id
     AND pessoa_pai_id = p_fornecedor_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_contato_fornec
    FROM pessoa
   WHERE pessoa_id = p_contato_fornec_id;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_aprovacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_carta_acordo.nextval
    INTO v_carta_acordo_id
    FROM dual;
  --
  v_flag_mostrar_ac := 'S';
  --
  SELECT nvl(MAX(num_carta_acordo), 0) + 1
    INTO v_num_carta_acordo
    FROM carta_acordo
   WHERE job_id = p_job_id;
  --
  INSERT INTO carta_acordo
   (carta_acordo_id,
    empresa_id,
    job_id,
    num_carta_acordo,
    data_criacao,
    fornecedor_id,
    contato_fornec_id,
    contato_fornec,
    cliente_id,
    emp_faturar_por_id,
    condicao_pagto_id,
    modo_pagto,
    fi_banco_fornec_id,
    num_agencia,
    num_conta,
    tipo_conta,
    flag_mostrar_ac,
    desc_item,
    instr_especiais,
    valor_aprovado,
    valor_fornecedor,
    perc_bv,
    perc_bv_pdr,
    motivo_atu_bv,
    perc_imposto,
    perc_imposto_pdr,
    motivo_atu_imp,
    tipo_fatur_bv,
    status,
    produtor_id,
    texto_xml,
    valor_credito_usado,
    flag_com_aprov,
    flag_com_prodcomp,
    flag_fornec_homolog,
    jus_fornec_naohmlg,
    nivel_excelencia,
    nivel_parceria,
    status_aceite,
    elaborador_id,
    cod_ext_carta)
  VALUES
   (v_carta_acordo_id,
    p_empresa_id,
    zvl(p_job_id, NULL),
    v_num_carta_acordo,
    SYSDATE,
    p_fornecedor_id,
    p_contato_fornec_id,
    v_contato_fornec,
    p_cliente_id,
    p_emp_faturar_por_id,
    zvl(p_condicao_pagto_id, NULL),
    TRIM(p_modo_pagto),
    zvl(p_emp_fi_banco_id, NULL),
    TRIM(p_emp_num_agencia),
    TRIM(p_emp_num_conta),
    TRIM(p_emp_tipo_conta),
    v_flag_mostrar_ac,
    TRIM(p_desc_item),
    TRIM(p_instr_especiais),
    0,
    0,
    v_perc_bv,
    v_perc_bv_pdr,
    TRIM(p_motivo_atu_bv),
    v_perc_imposto,
    v_perc_imposto_pdr,
    TRIM(p_motivo_atu_imp),
    v_tipo_fatur_bv,
    'EMAPRO',
    p_produtor_id,
    v_xml_carta,
    v_valor_credito,
    p_flag_com_aprovacao,
    'S',
    v_flag_fornec_homolog,
    TRIM(p_jus_fornec_naohmlg),
    v_nivel_excelencia,
    v_nivel_parceria,
    v_status_aceite,
    p_usuario_sessao_id,
    TRIM(p_cod_ext_carta));
  --
  v_num_carta_formatado := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
  --
  UPDATE carta_acordo
     SET num_carta_formatado = v_num_carta_formatado
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_tipo_item_ant         := NULL;
  v_flag_pago_cliente_ant := NULL;
  --
  v_delimitador         := '|';
  v_valor_aprovado_ca   := 0;
  v_valor_fornecedor_ca := 0;
  --
  v_vetor_item_id           := p_vetor_item_id;
  v_vetor_quantidade        := p_vetor_quantidade;
  v_vetor_frequencia        := p_vetor_frequencia;
  v_vetor_custo_unitario    := p_vetor_custo_unitario;
  v_vetor_complemento       := p_vetor_complemento;
  v_vetor_tipo_produto_id   := p_vetor_tipo_produto_id;
  v_vetor_valor_aprovado    := p_vetor_valor_aprovado;
  v_vetor_valor_fornecedor  := p_vetor_valor_fornecedor;
  v_vetor_produto_fiscal_id := p_vetor_produto_fiscal_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id               := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_tipo_produto_id       := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_quantidade_char       := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char       := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char   := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento           := TRIM(prox_valor_retornar(v_vetor_complemento, v_delimitador));
   v_valor_fornecedor_char := TRIM(prox_valor_retornar(v_vetor_valor_fornecedor, v_delimitador));
   v_valor_aprovado_char   := TRIM(prox_valor_retornar(v_vetor_valor_aprovado, v_delimitador));
   v_produto_fiscal_id     := to_number(prox_valor_retornar(v_vetor_produto_fiscal_id,
                                                            v_delimitador));
   --
   SELECT MAX(job_id)
     INTO v_job_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_job_id <> v_job_id
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não pertence ao ' || v_lbl_job || ' informado (' || to_char(v_item_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE tipo_produto_id = nvl(v_tipo_produto_id, -1)
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse entregável não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_prod_fiscal = 'S' AND nvl(v_produto_fiscal_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do produto fiscal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_produto_fiscal_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_fiscal
     WHERE produto_fiscal_id = v_produto_fiscal_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse produto fiscal não existe ou não pertence a essa empresa (' ||
                   to_char(v_produto_fiscal_id) || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_item,
          flag_pago_cliente,
          orcamento_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_tipo_item,
          v_tipo_item_ori,
          v_flag_pago_cliente,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 AND
     --ALCBO_230524
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma carta acordo com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido (' ||
                  v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma carta acordo.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF numero_validar(v_custo_unitario_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_quantidade_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_frequencia_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_fornecedor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_aprovado_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_unitario   := nvl(numero_converter(v_custo_unitario_char), 0);
   v_quantidade       := nvl(numero_converter(v_quantidade_char), 0);
   v_frequencia       := nvl(numero_converter(v_frequencia_char), 0);
   v_valor_aprovado   := nvl(moeda_converter(v_valor_aprovado_char), 0);
   v_valor_fornecedor := nvl(moeda_converter(v_valor_fornecedor_char), 0);
   --
   IF v_valor_aprovado < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo do fornecedor inválido (' || v_nome_item || ': ' ||
                  moeda_mostrar(v_valor_fornecedor, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor > v_valor_aprovado
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O custo do fornecedor não pode ser maior que o valor aprovado (' || v_nome_item || ': ' ||
                  moeda_mostrar(v_valor_fornecedor, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o valor orçado (' ||
                  moeda_mostrar(v_valor_aprovado_it, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ori = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                   moeda_mostrar(v_valor_aprovado, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_aprovado > v_valor_disponivel
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > 0 OR v_valor_fornecedor > 0
   THEN
    --
    INSERT INTO item_carta
     (item_carta_id,
      carta_acordo_id,
      item_id,
      tipo_produto_id,
      valor_aprovado,
      valor_fornecedor,
      custo_unitario,
      quantidade,
      frequencia,
      complemento,
      produto_fiscal_id)
    VALUES
     (seq_item_carta.nextval,
      v_carta_acordo_id,
      v_item_id,
      v_tipo_produto_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      v_custo_unitario,
      v_quantidade,
      v_frequencia,
      v_complemento,
      zvl(v_produto_fiscal_id, NULL));
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    v_valor_aprovado_ca   := v_valor_aprovado_ca + v_valor_aprovado;
    v_valor_fornecedor_ca := v_valor_fornecedor_ca + v_valor_fornecedor;
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais e atualizacao da carta acordo
  ------------------------------------------------------------
  --
  IF v_valor_aprovado_ca = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor foi informado para os itens dessa carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo total do fornecedor (' || moeda_mostrar(v_valor_fornecedor_ca, 'S') ||
                 ') não pode ser maior que o valor total aprovado pelo cliente (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF TRIM(p_perc_imposto) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   UPDATE carta_acordo
      SET perc_imposto = 0
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
    INTO v_flag_pago_cliente
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = v_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_flag_mostrar_ac := 'N';
  ELSE
   v_flag_mostrar_ac := 'S';
  END IF;
  --
  UPDATE carta_acordo
     SET valor_aprovado   = v_valor_aprovado_ca,
         valor_fornecedor = v_valor_fornecedor_ca,
         flag_mostrar_ac  = v_flag_mostrar_ac
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- consistencias de item_carta
  ------------------------------------------------------------
  -- verificacao de valores aprovados X qtd*freq*unitario
  --ALCBO_080425
  IF v_flag_pago_cliente = 'S'
  THEN
   FOR r_va IN c_va
   LOOP
    p_erro_cod := '90000';
    p_erro_msg := 'O entregável "' || r_va.produto || '" apresenta o valor ' ||
                  'R$ Forcecedor (qtd X freq X unitário) diferente da somatória dos Valores da Nota lançados (' ||
                  'R$ Forcecedor: ' || moeda_mostrar(r_va.valor_calculado, 'S') ||
                  ' ; Valores da Nota: ' || moeda_mostrar(r_va.valor_lancado, 'S') || ')';
   
    RAISE v_exception;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de sobras
  ------------------------------------------------------------
  v_delimitador := '|';
  v_sobra_id    := NULL;
  --
  v_vetor_sobra_item_id := p_vetor_sobra_item_id;
  v_vetor_sobra_valores := p_vetor_sobra_valores;
  --
  WHILE nvl(length(rtrim(v_vetor_sobra_item_id)), 0) > 0
  LOOP
   v_item_id          := to_number(prox_valor_retornar(v_vetor_sobra_item_id, v_delimitador));
   v_valor_sobra_char := prox_valor_retornar(v_vetor_sobra_valores, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item inválido no vetor de sobras (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          job_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_job_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF moeda_validar(v_valor_sobra_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_sobra := nvl(moeda_converter(v_valor_sobra_char), 0);
   --
   IF v_valor_sobra < 0 OR v_valor_sobra > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_sobra > 0
   THEN
    SELECT MAX(sobra_id)
      INTO v_sobra_id
      FROM sobra
     WHERE job_id = v_job_id
       AND carta_acordo_id = v_carta_acordo_id;
    --
    IF v_sobra_id IS NULL
    THEN
     SELECT seq_sobra.nextval
       INTO v_sobra_id
       FROM dual;
     --
     INSERT INTO sobra
      (sobra_id,
       job_id,
       carta_acordo_id,
       usuario_resp_id,
       data_entrada,
       tipo_sobra,
       justificativa,
       valor_sobra,
       valor_cred_cliente,
       flag_dentro_ca)
     VALUES
      (v_sobra_id,
       v_job_id,
       v_carta_acordo_id,
       p_usuario_sessao_id,
       SYSDATE,
       'SOB',
       NULL,
       0,
       0,
       'N');
    
    END IF;
    --
    INSERT INTO item_sobra
     (item_sobra_id,
      item_id,
      sobra_id,
      valor_sobra_item,
      valor_cred_item,
      flag_abate_fatur)
    VALUES
     (seq_item_sobra.nextval,
      v_item_id,
      v_sobra_id,
      v_valor_sobra,
      0,
      'N');
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF; -- fim do IF v_valor_sobra > 0
  END LOOP;
  --
  UPDATE sobra so
     SET valor_sobra =
         (SELECT nvl(SUM(valor_sobra_item), 0)
            FROM item_sobra it
           WHERE it.sobra_id = so.sobra_id)
   WHERE so.carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       v_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito > 0
  THEN
   -- a agencia usa o credito junto ao fornecedor (movimento de saida)
   v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' || v_num_carta_formatado;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     p_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_credito,
     'S',
     v_operador,
     NULL);
  
  END IF;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, p_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
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
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(v_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_carta_acordo_id,
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
  p_carta_acordo_id := v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- verificacao da existencia de usuario aprovador
  ------------------------------------------------------------
  IF p_flag_com_aprovacao = 'S' AND
     carta_acordo_pkg.usuario_aprov_verificar(p_empresa_id, v_carta_acordo_id) = 0
  THEN
   p_erro_cod := '10000';
   p_erro_msg := 'Não há nenhum Aprovador configurado para aprovar esta AO. A AO será enviada mesmo assim.';
  ELSE
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  END IF;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de carta acordo já existe (' || v_num_carta_formatado ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END monojob_adicionar;
 --
 --
 PROCEDURE multijob_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/10/2013
  -- DESCRICAO: Inclusão de CARTA_ACORDO multijob com produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  -- Silvia            25/11/2014  Verificacao da existencia de usuario aprovador
  -- Silvia            02/12/2014  Novo parametro job_id para carta monojob.
  -- Silvia            04/02/2015  Novo parametro flag_com_aprovacao
  -- Silvia            27/03/2015  Novo atributo flag_com_prodcomp
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            13/07/2015  Novo parametro de justificativa fornec nao homologado.
  --                               Instanciacao de dados do fornecedor.
  -- Silvia            09/09/2015  Controle de aceitacao.
  -- Silvia            23/05/2014  Registro do elaborador.
  -- Silvia            04/05/2016  Guarda numero formatado da carta acordo.
  -- Silvia            07/05/2018  Guarda empresa_id na carta acordo
  -- Silvia            18/06/2018  Novo parametro produto_fiscal_id.
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Silvia            29/09/2020  Indicacao de sobras
  -- Ana Luiza         07/11/2024  Impedimento de usuario selecionar da inferior a data atual
  -- Ana Luiza         06/08/2028  Tratativa para voltar o ultimo registro da tab pessoa_homolog
 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_job_id                  IN job.job_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_jus_fornec_naohmlg      IN VARCHAR2,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao      IN VARCHAR2,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_carta_acordo_id         OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_job_id                  job.job_id%TYPE;
  v_num_job                 job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_flag_bloq_negoc         job.flag_bloq_negoc%TYPE;
  v_orcamento_id            item.orcamento_id%TYPE;
  v_item_id                 item.item_id%TYPE;
  v_valor_aprovado_it       item.valor_aprovado%TYPE;
  v_tipo_item_ori           VARCHAR2(10);
  v_tipo_item               VARCHAR2(10);
  v_tipo_item_ant           VARCHAR2(10);
  v_flag_pago_cliente       item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant   item.flag_pago_cliente%TYPE;
  v_nome_item               VARCHAR2(200);
  v_carta_acordo_id         carta_acordo.carta_acordo_id%TYPE;
  v_num_carta_formatado     carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado          carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor        carta_acordo.valor_fornecedor%TYPE;
  v_valor_aprovado_ca       carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca     carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv                 carta_acordo.perc_bv%TYPE;
  v_perc_imposto            carta_acordo.perc_imposto%TYPE;
  v_num_carta_acordo        carta_acordo.num_carta_acordo%TYPE;
  v_tipo_fatur_bv           carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr             carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr        carta_acordo.perc_imposto_pdr%TYPE;
  v_flag_mostrar_ac         carta_acordo.flag_mostrar_ac%TYPE;
  v_valor_credito           carta_acordo.valor_credito_usado%TYPE;
  v_contato_fornec          carta_acordo.contato_fornec%TYPE;
  v_status_aceite           carta_acordo.status_aceite%TYPE;
  v_operador                lancamento.operador%TYPE;
  v_descricao               lancamento.descricao%TYPE;
  v_fornecedor              pessoa.apelido%TYPE;
  v_flag_fornec_homolog     CHAR(1);
  v_nivel_excelencia        NUMBER(5, 2);
  v_nivel_parceria          NUMBER(5, 2);
  v_tipo_produto_id         tipo_produto.tipo_produto_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_parc_datas        LONG;
  v_vetor_parc_valores      LONG;
  v_vetor_parc_num_dias     LONG;
  v_vetor_item_id           LONG;
  v_vetor_tipo_produto_id   LONG;
  v_vetor_produto_fiscal_id LONG;
  v_vetor_quantidade        LONG;
  v_vetor_frequencia        LONG;
  v_vetor_custo_unitario    LONG;
  v_vetor_complemento       LONG;
  v_vetor_sobra_valores     LONG;
  v_vetor_sobra_item_id     LONG;
  v_data_parcela_char       VARCHAR2(50);
  v_valor_parcela_char      VARCHAR2(50);
  v_num_dias_char           VARCHAR2(50);
  v_quantidade_char         VARCHAR2(50);
  v_frequencia_char         VARCHAR2(50);
  v_custo_unitario_char     VARCHAR2(50);
  v_valor_sobra_char        VARCHAR2(50);
  v_complemento             VARCHAR2(32000);
  v_sobra_id                sobra.sobra_id%TYPE;
  v_valor_sobra             item_sobra.valor_sobra_item%TYPE;
  v_quantidade              item_carta.quantidade%TYPE;
  v_frequencia              item_carta.frequencia%TYPE;
  v_custo_unitario          item_carta.custo_unitario%TYPE;
  v_produto_fiscal_id       item_carta.produto_fiscal_id%TYPE;
  v_data_parcela            parcela_carta.data_parcela%TYPE;
  v_valor_parcela           parcela_carta.valor_parcela%TYPE;
  v_num_dias                parcela_carta.num_dias%TYPE;
  v_num_dias_ant            parcela_carta.num_dias%TYPE;
  v_parcela_carta_id        parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela             parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant        parcela_carta.data_parcela%TYPE;
  v_valor_acumulado         NUMBER;
  v_tipo_data               VARCHAR2(10);
  v_tipo_data_ant           VARCHAR2(10);
  v_xml_doc                 VARCHAR2(100);
  v_xml_entrega             xmltype;
  v_xml_montagem            xmltype;
  v_xml_prest_servico       xmltype;
  v_xml_desmontagem         xmltype;
  v_xml_evento              xmltype;
  v_xml_corpo               xmltype;
  v_xml_carta               VARCHAR2(4000);
  v_valor_disponivel        NUMBER;
  v_valor_liberado_b        NUMBER;
  v_lbl_job                 VARCHAR2(100);
  v_flag_multijob           VARCHAR2(20);
  v_flag_bv_faturar         VARCHAR2(20);
  v_flag_bv_abater          VARCHAR2(20);
  v_flag_bv_creditar        VARCHAR2(20);
  v_flag_bv_permutar        VARCHAR2(20);
  v_flag_pgto_manual        VARCHAR2(20);
  v_flag_pgto_tabela        VARCHAR2(20);
  v_flag_com_forma_pag      VARCHAR2(20);
  v_flag_justificar         VARCHAR2(20);
  v_flag_com_aceite         VARCHAR2(20);
  v_flag_prod_fiscal        VARCHAR2(20);
  v_sigla_multijob          VARCHAR2(100);
  v_local_parcelam_fornec   VARCHAR2(50);
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  --
 BEGIN
  v_qt                    := 0;
  p_carta_acordo_id       := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_multijob         := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_MULTIJOB');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_sigla_multijob        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_SIGLA_MULTIJOB');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_flag_justificar       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'JUSTIFICAR_FORNEC_NAOHMLG');
  v_flag_com_aceite       := empresa_pkg.parametro_retornar(p_empresa_id,
                                                            'CA_HABILITA_ACEITE_FORNEC');
  v_flag_prod_fiscal      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COM_PRODUTO_FISCAL');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF v_flag_multijob = 'N' AND nvl(p_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Carta acordo multijob não habilitada para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_sigla_multijob) IS NULL AND nvl(p_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sigla da carta acordo multijob não definida para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_com_aceite = 'S'
  THEN
   v_status_aceite := 'PEND';
  ELSE
   v_status_aceite := 'NA';
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT p.apelido,
         nvl(ph.perc_bv, 0),
         nvl(ph.perc_imposto, 0),
         decode(ph.status_para, 'NAPL', 'S', 'HMLG', 'S', 'N'),
         p.nivel_qualidade,
         p.nivel_parceria
    INTO v_fornecedor,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_flag_fornec_homolog,
         v_nivel_excelencia,
         v_nivel_parceria
    FROM pessoa p
    LEFT JOIN pessoa_homolog ph
      ON p.pessoa_id = ph.pessoa_id
   WHERE p.pessoa_id = p_fornecedor_id
     AND ph.flag_atual = 'S'
     AND ph.data_hora = (SELECT MAX(data_hora)
                           FROM pessoa_homolog
                          WHERE pessoa_id = p_fornecedor_id); --ALCBO_060825;
  --
  IF v_flag_fornec_homolog = 'N' AND v_flag_justificar = 'S' AND TRIM(p_jus_fornec_naohmlg) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado deve ser informada.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_jus_fornec_naohmlg) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa de contratação de fornecedor não homologado ' ||
                 'não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_fornec_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_filho_id = p_contato_fornec_id
     AND pessoa_pai_id = p_fornecedor_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_contato_fornec
    FROM pessoa
   WHERE pessoa_id = p_contato_fornec_id;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --ALCBO_071124
  IF v_flag_pgto_tabela = 'S' AND p_condicao_pagto_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  /*IF p_vetor_parc_datas IS NOT NULL THEN
   --    
   v_delimitador      := '|';
   v_vetor_parc_datas := p_vetor_parc_datas;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0
   LOOP
    --
    v_data_parcela_char := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela := data_converter(v_data_parcela_char);
    --
    IF trunc(v_data_parcela) < trunc(SYSDATE) THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A data informada (' || to_char(v_data_parcela, 'DD/MM/YYYY') ||
                   ') é inferior à data de hoje (' || to_char(SYSDATE, 'DD/MM/YYYY') || '). ' ||
                   'Não é permitido informar uma data retroativa. Por favor, informe uma data a partir de hoje.';
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;*/ --ALCBO_071124F
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_aprovacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_carta_acordo.nextval
    INTO v_carta_acordo_id
    FROM dual;
  --
  v_flag_mostrar_ac := 'S';
  --
  IF nvl(p_job_id, 0) = 0
  THEN
   -- numeracao de carta acordo multijob
   SELECT nvl(MAX(num_carta_acordo), 0) + 1
     INTO v_num_carta_acordo
     FROM carta_acordo
    WHERE job_id IS NULL;
  
  ELSE
   -- numeracao de carta acordo monojob
   SELECT nvl(MAX(num_carta_acordo), 0) + 1
     INTO v_num_carta_acordo
     FROM carta_acordo
    WHERE job_id = p_job_id;
  
  END IF;
  --
  INSERT INTO carta_acordo
   (carta_acordo_id,
    empresa_id,
    job_id,
    num_carta_acordo,
    data_criacao,
    fornecedor_id,
    contato_fornec_id,
    contato_fornec,
    cliente_id,
    emp_faturar_por_id,
    condicao_pagto_id,
    modo_pagto,
    fi_banco_fornec_id,
    num_agencia,
    num_conta,
    tipo_conta,
    flag_mostrar_ac,
    desc_item,
    instr_especiais,
    valor_aprovado,
    valor_fornecedor,
    perc_bv,
    perc_bv_pdr,
    motivo_atu_bv,
    perc_imposto,
    perc_imposto_pdr,
    motivo_atu_imp,
    tipo_fatur_bv,
    status,
    produtor_id,
    texto_xml,
    valor_credito_usado,
    flag_com_aprov,
    flag_com_prodcomp,
    flag_fornec_homolog,
    jus_fornec_naohmlg,
    nivel_excelencia,
    nivel_parceria,
    status_aceite,
    elaborador_id,
    cod_ext_carta)
  VALUES
   (v_carta_acordo_id,
    p_empresa_id,
    zvl(p_job_id, NULL),
    v_num_carta_acordo,
    SYSDATE,
    p_fornecedor_id,
    p_contato_fornec_id,
    v_contato_fornec,
    p_cliente_id,
    p_emp_faturar_por_id,
    zvl(p_condicao_pagto_id, NULL),
    TRIM(p_modo_pagto),
    zvl(p_emp_fi_banco_id, NULL),
    TRIM(p_emp_num_agencia),
    TRIM(p_emp_num_conta),
    TRIM(p_emp_tipo_conta),
    v_flag_mostrar_ac,
    TRIM(p_desc_item),
    TRIM(p_instr_especiais),
    0,
    0,
    v_perc_bv,
    v_perc_bv_pdr,
    TRIM(p_motivo_atu_bv),
    v_perc_imposto,
    v_perc_imposto_pdr,
    TRIM(p_motivo_atu_imp),
    v_tipo_fatur_bv,
    'EMAPRO',
    p_produtor_id,
    v_xml_carta,
    v_valor_credito,
    p_flag_com_aprovacao,
    'S',
    v_flag_fornec_homolog,
    TRIM(p_jus_fornec_naohmlg),
    v_nivel_excelencia,
    v_nivel_parceria,
    v_status_aceite,
    p_usuario_sessao_id,
    TRIM(p_cod_ext_carta));
  --
  v_num_carta_formatado := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
  --
  UPDATE carta_acordo
     SET num_carta_formatado = v_num_carta_formatado
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_tipo_item_ant         := NULL;
  v_flag_pago_cliente_ant := NULL;
  --
  v_delimitador         := '|';
  v_valor_aprovado_ca   := 0;
  v_valor_fornecedor_ca := 0;
  --
  v_vetor_item_id           := p_vetor_item_id;
  v_vetor_quantidade        := p_vetor_quantidade;
  v_vetor_frequencia        := p_vetor_frequencia;
  v_vetor_custo_unitario    := p_vetor_custo_unitario;
  v_vetor_complemento       := p_vetor_complemento;
  v_vetor_tipo_produto_id   := p_vetor_tipo_produto_id;
  v_vetor_produto_fiscal_id := p_vetor_produto_fiscal_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id             := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_tipo_produto_id     := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_quantidade_char     := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char     := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento         := TRIM(prox_valor_retornar(v_vetor_complemento, v_delimitador));
   v_produto_fiscal_id   := to_number(prox_valor_retornar(v_vetor_produto_fiscal_id, v_delimitador));
   --
   SELECT MAX(job_id),
          MAX(orcamento_id)
     INTO v_job_id,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_job_id, 0) > 0 AND p_job_id <> v_job_id
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não pertence ao ' || v_lbl_job || ' informado (' || to_char(v_item_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE tipo_produto_id = nvl(v_tipo_produto_id, -1)
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse entregável não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_prod_fiscal = 'S' AND nvl(v_produto_fiscal_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do produto fiscal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_produto_fiscal_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_fiscal
     WHERE produto_fiscal_id = v_produto_fiscal_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse produto fiscal não existe ou não pertence a essa empresa (' ||
                   to_char(v_produto_fiscal_id) || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   SELECT jo.numero,
          jo.status,
          jo.flag_bloq_negoc
     INTO v_num_job,
          v_status_job,
          v_flag_bloq_negoc
     FROM job jo
    WHERE jo.job_id = v_job_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O status do ' || v_lbl_job || ' ' || v_num_job || ' não permite essa operação.';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_item,
          flag_pago_cliente
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_tipo_item,
          v_tipo_item_ori,
          v_flag_pago_cliente
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma carta acordo com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido (' ||
                  v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma carta acordo.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF numero_validar(v_custo_unitario_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_quantidade_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_frequencia_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_unitario   := nvl(numero_converter(v_custo_unitario_char), 0);
   v_quantidade       := nvl(numero_converter(v_quantidade_char), 0);
   v_frequencia       := nvl(numero_converter(v_frequencia_char), 0);
   v_valor_aprovado   := round(v_quantidade * v_frequencia * v_custo_unitario, 2);
   v_valor_fornecedor := v_valor_aprovado;
   --
   IF v_valor_aprovado <= 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o valor orçado (' ||
                  moeda_mostrar(v_valor_aprovado_it, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ori = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                   moeda_mostrar(v_valor_aprovado, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_aprovado > v_valor_disponivel
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > 0 OR v_valor_fornecedor > 0
   THEN
    /*
    SELECT COUNT(*)
      INTO v_qt
      FROM item_carta
     WHERE carta_acordo_id = v_carta_acordo_id
       AND item_id = v_item_id;
    --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O item ' || v_nome_item ||
                     ', não pode ser lançado na carta acordo mais de uma vez.';
       RAISE v_exception;
    END IF;*/
    --
    INSERT INTO item_carta
     (item_carta_id,
      carta_acordo_id,
      item_id,
      tipo_produto_id,
      valor_aprovado,
      valor_fornecedor,
      custo_unitario,
      quantidade,
      frequencia,
      complemento,
      produto_fiscal_id)
    VALUES
     (seq_item_carta.nextval,
      v_carta_acordo_id,
      v_item_id,
      v_tipo_produto_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      v_custo_unitario,
      v_quantidade,
      v_frequencia,
      v_complemento,
      zvl(v_produto_fiscal_id, NULL));
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    v_valor_aprovado_ca   := v_valor_aprovado_ca + v_valor_aprovado;
    v_valor_fornecedor_ca := v_valor_fornecedor_ca + v_valor_fornecedor;
   END IF;
   --
   -- trata status do job
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais e atualizacao da carta acordo
  ------------------------------------------------------------
  --
  IF v_valor_aprovado_ca = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor foi informado para os itens dessa carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo total do fornecedor (' || moeda_mostrar(v_valor_fornecedor_ca, 'S') ||
                 ') não pode ser maior que o valor total aprovado pelo cliente (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF TRIM(p_perc_imposto) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   UPDATE carta_acordo
      SET perc_imposto = 0
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
    INTO v_flag_pago_cliente
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = v_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_flag_mostrar_ac := 'N';
  ELSE
   v_flag_mostrar_ac := 'S';
  END IF;
  --
  UPDATE carta_acordo
     SET valor_aprovado   = v_valor_aprovado_ca,
         valor_fornecedor = v_valor_fornecedor_ca,
         flag_mostrar_ac  = v_flag_mostrar_ac
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de sobras
  ------------------------------------------------------------
  v_delimitador := '|';
  v_sobra_id    := NULL;
  --
  v_vetor_sobra_item_id := p_vetor_sobra_item_id;
  v_vetor_sobra_valores := p_vetor_sobra_valores;
  --
  WHILE nvl(length(rtrim(v_vetor_sobra_item_id)), 0) > 0
  LOOP
   v_item_id          := to_number(prox_valor_retornar(v_vetor_sobra_item_id, v_delimitador));
   v_valor_sobra_char := prox_valor_retornar(v_vetor_sobra_valores, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item inválido no vetor de sobras (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          job_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_job_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF moeda_validar(v_valor_sobra_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_sobra := nvl(moeda_converter(v_valor_sobra_char), 0);
   --
   IF v_valor_sobra < 0 OR v_valor_sobra > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_sobra > 0
   THEN
    SELECT MAX(sobra_id)
      INTO v_sobra_id
      FROM sobra
     WHERE job_id = v_job_id
       AND carta_acordo_id = v_carta_acordo_id;
    --
    IF v_sobra_id IS NULL
    THEN
     SELECT seq_sobra.nextval
       INTO v_sobra_id
       FROM dual;
     --
     INSERT INTO sobra
      (sobra_id,
       job_id,
       carta_acordo_id,
       usuario_resp_id,
       data_entrada,
       tipo_sobra,
       justificativa,
       valor_sobra,
       valor_cred_cliente,
       flag_dentro_ca)
     VALUES
      (v_sobra_id,
       v_job_id,
       v_carta_acordo_id,
       p_usuario_sessao_id,
       SYSDATE,
       'SOB',
       NULL,
       0,
       0,
       'N');
    
    END IF;
    --
    INSERT INTO item_sobra
     (item_sobra_id,
      item_id,
      sobra_id,
      valor_sobra_item,
      valor_cred_item,
      flag_abate_fatur)
    VALUES
     (seq_item_sobra.nextval,
      v_item_id,
      v_sobra_id,
      v_valor_sobra,
      0,
      'N');
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF; -- fim do IF v_valor_sobra > 0
  END LOOP;
  --
  UPDATE sobra so
     SET valor_sobra =
         (SELECT nvl(SUM(valor_sobra_item), 0)
            FROM item_sobra it
           WHERE it.sobra_id = so.sobra_id)
   WHERE so.carta_acordo_id = v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       v_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = v_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito > 0
  THEN
   -- a agencia usa o credito junto ao fornecedor (movimento de saida)
   v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' || v_num_carta_formatado;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     p_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_credito,
     'S',
     v_operador,
     NULL);
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
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
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(v_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_carta_acordo_id,
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
  p_carta_acordo_id := v_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- verificacao da existencia de usuario aprovador
  ------------------------------------------------------------
  IF p_flag_com_aprovacao = 'S' AND
     carta_acordo_pkg.usuario_aprov_verificar(p_empresa_id, v_carta_acordo_id) = 0
  THEN
   p_erro_cod := '10000';
   p_erro_msg := 'Não há nenhum Aprovador configurado para aprovar esta AO. A AO será enviada mesmo assim.';
  ELSE
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  END IF;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de carta acordo já existe (' || v_num_carta_formatado ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END multijob_adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/04/2007
  -- DESCRICAO: Atualização de CARTA_ACORDO sem produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta multi-item.
  -- Silvia            29/02/2008  Tipo de faturamento do BV (novo valor 'NA')
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            16/03/2009  Novos campos em carta acordo (perc padrao, contato).
  -- Silvia            27/03/2009  Zera imposto  do fornecedor qdo nao faz sentido
  -- Silvia            29/05/2009  Consiste bloqueio da negociacao
  -- Silvia            08/02/2011  Novo parametro flag_mostrar_ac.
  -- Silvia            25/02/2014  Parametro contato fornecedor passou a aceitar ID ou string
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            26/12/2016  Sempre limpa a tabela carta_fluxo_aprov
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_carta_acordo_id      IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id        IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id           IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id   IN carta_acordo.emp_faturar_por_id%TYPE,
  p_flag_mostrar_ac      IN carta_acordo.flag_mostrar_ac%TYPE,
  p_contato_fornec       IN carta_acordo.contato_fornec%TYPE,
  p_desc_item            IN VARCHAR2,
  p_valor_credito        IN VARCHAR2,
  p_perc_bv              IN VARCHAR2,
  p_motivo_atu_bv        IN VARCHAR2,
  p_perc_imposto         IN VARCHAR2,
  p_motivo_atu_imp       IN VARCHAR2,
  p_tipo_fatur_bv        IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_parc_datas     IN VARCHAR2,
  p_vetor_parc_num_dias  IN VARCHAR2,
  p_tipo_num_dias        IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores   IN VARCHAR2,
  p_condicao_pagto_id    IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto           IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id      IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia      IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta        IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta       IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar   IN VARCHAR2,
  p_instr_especiais      IN VARCHAR2,
  p_entre_data_prototipo IN VARCHAR2,
  p_entre_data_produto   IN VARCHAR2,
  p_entre_local          IN VARCHAR2,
  p_monta_hora_ini       IN VARCHAR2,
  p_monta_data_ini       IN VARCHAR2,
  p_monta_hora_fim       IN VARCHAR2,
  p_monta_data_fim       IN VARCHAR2,
  p_pserv_hora_ini       IN VARCHAR2,
  p_pserv_data_ini       IN VARCHAR2,
  p_pserv_hora_fim       IN VARCHAR2,
  p_pserv_data_fim       IN VARCHAR2,
  p_desmo_hora_ini       IN VARCHAR2,
  p_desmo_data_ini       IN VARCHAR2,
  p_desmo_hora_fim       IN VARCHAR2,
  p_desmo_data_fim       IN VARCHAR2,
  p_event_desc           IN VARCHAR2,
  p_event_local          IN VARCHAR2,
  p_event_hora_ini       IN VARCHAR2,
  p_event_data_ini       IN VARCHAR2,
  p_event_hora_fim       IN VARCHAR2,
  p_event_data_fim       IN VARCHAR2,
  p_produtor_id          IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta        IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_job_id                job.job_id%TYPE;
  v_num_job               job.numero%TYPE;
  v_status_job            job.status%TYPE;
  v_flag_bloq_negoc       job.flag_bloq_negoc%TYPE;
  v_num_carta_formatado   carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ca     carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca   carta_acordo.valor_fornecedor%TYPE;
  v_valor_credito         carta_acordo.valor_credito_usado%TYPE;
  v_valor_credito_old     carta_acordo.valor_credito_usado%TYPE;
  v_perc_bv               carta_acordo.perc_bv%TYPE;
  v_perc_imposto          carta_acordo.perc_imposto%TYPE;
  v_status_ca             carta_acordo.status%TYPE;
  v_tipo_fatur_bv         carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr           carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr      carta_acordo.perc_imposto_pdr%TYPE;
  v_fornecedor_old_id     carta_acordo.fornecedor_id%TYPE;
  v_contato_fornec_id     carta_acordo.contato_fornec_id%TYPE;
  v_contato_fornec        carta_acordo.contato_fornec%TYPE;
  v_flag_com_aprov        carta_acordo.flag_com_aprov%TYPE;
  v_operador              lancamento.operador%TYPE;
  v_descricao             lancamento.descricao%TYPE;
  v_fornecedor            pessoa.apelido%TYPE;
  v_delimitador           CHAR(1);
  v_vetor_parc_datas      LONG;
  v_vetor_parc_valores    LONG;
  v_vetor_parc_num_dias   LONG;
  v_data_parcela_char     VARCHAR2(20);
  v_valor_parcela_char    VARCHAR2(20);
  v_num_dias_char         VARCHAR2(20);
  v_data_parcela          parcela_carta.data_parcela%TYPE;
  v_valor_parcela         parcela_carta.valor_parcela%TYPE;
  v_num_dias              parcela_carta.num_dias%TYPE;
  v_num_dias_ant          parcela_carta.num_dias%TYPE;
  v_parcela_carta_id      parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela           parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant      parcela_carta.data_parcela%TYPE;
  v_valor_acumulado       NUMBER;
  v_tipo_data             VARCHAR2(10);
  v_tipo_data_ant         VARCHAR2(10);
  v_xml_doc               VARCHAR2(100);
  v_xml_entrega           xmltype;
  v_xml_montagem          xmltype;
  v_xml_prest_servico     xmltype;
  v_xml_desmontagem       xmltype;
  v_xml_evento            xmltype;
  v_xml_corpo             xmltype;
  v_xml_carta             VARCHAR2(4000);
  v_lbl_job               VARCHAR2(100);
  v_flag_bv_faturar       VARCHAR2(20);
  v_flag_bv_abater        VARCHAR2(20);
  v_flag_bv_creditar      VARCHAR2(20);
  v_flag_bv_permutar      VARCHAR2(20);
  v_flag_pgto_manual      VARCHAR2(20);
  v_flag_pgto_tabela      VARCHAR2(20);
  v_flag_com_forma_pag    VARCHAR2(20);
  v_local_parcelam_fornec VARCHAR2(50);
  v_xml_antes             CLOB;
  v_xml_atual             CLOB;
  v_xml_antes_fo          CLOB;
  v_xml_atual_fo          CLOB;
  --
 BEGIN
  v_qt                    := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         ca.flag_com_aprov,
         jo.numero,
         jo.status,
         jo.flag_bloq_negoc,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv_pdr, 0),
         nvl(ca.perc_imposto_pdr, 0),
         nvl(ca.valor_credito_usado, 0),
         ca.fornecedor_id
    INTO v_job_id,
         v_status_ca,
         v_flag_com_aprov,
         v_num_job,
         v_status_job,
         v_flag_bloq_negoc,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_valor_credito_old,
         v_fornecedor_old_id
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca = 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não pode ser alterada pois já foi emitida.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca = 'REPROV'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_A',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
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
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(nvl(TRIM(p_contato_fornec), '0')) = 1
  THEN
   -- veio contato nulo ou inteiro
   v_contato_fornec_id := to_number(nvl(TRIM(p_contato_fornec), '0'));
   --
   IF v_contato_fornec_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao
    WHERE pessoa_filho_id = v_contato_fornec_id
      AND pessoa_pai_id = p_fornecedor_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
    RAISE v_exception;
   END IF;
   --
   SELECT apelido
     INTO v_contato_fornec
     FROM pessoa
    WHERE pessoa_id = v_contato_fornec_id;
  
  ELSE
   -- veio o nome do contato
   v_contato_fornec    := TRIM(p_contato_fornec);
   v_contato_fornec_id := NULL;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_fornecedor
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_mostrar_ac) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag mostrar "aos cuidados de" inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_perc_imposto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   v_perc_imposto := 0;
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id
      AND it.flag_pago_cliente = 'S';
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET fornecedor_id       = p_fornecedor_id,
         cliente_id          = p_cliente_id,
         emp_faturar_por_id  = p_emp_faturar_por_id,
         flag_mostrar_ac     = p_flag_mostrar_ac,
         contato_fornec_id   = v_contato_fornec_id,
         contato_fornec      = v_contato_fornec,
         desc_item           = TRIM(p_desc_item),
         instr_especiais     = TRIM(p_instr_especiais),
         perc_bv             = v_perc_bv,
         motivo_atu_bv       = TRIM(p_motivo_atu_bv),
         perc_imposto        = v_perc_imposto,
         motivo_atu_imp      = TRIM(p_motivo_atu_imp),
         tipo_fatur_bv       = v_tipo_fatur_bv,
         produtor_id         = p_produtor_id,
         texto_xml           = v_xml_carta,
         condicao_pagto_id   = zvl(p_condicao_pagto_id, NULL),
         modo_pagto          = TRIM(p_modo_pagto),
         fi_banco_fornec_id  = zvl(p_emp_fi_banco_id, NULL),
         num_agencia         = TRIM(p_emp_num_agencia),
         num_conta           = TRIM(p_emp_num_conta),
         tipo_conta          = TRIM(p_emp_tipo_conta),
         valor_credito_usado = v_valor_credito,
         cod_ext_carta       = TRIM(p_cod_ext_carta)
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  DELETE FROM parcela_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       p_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito <> v_valor_credito_old OR p_fornecedor_id <> v_fornecedor_old_id
  THEN
   -- valor do credito ou fornecedor alterados
   IF v_valor_credito_old > 0
   THEN
    -- estorno do uso do credito pela agencia junto ao fornecedor (movimento de entrada)
    v_descricao := 'Estorno do uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      v_fornecedor_old_id,
      SYSDATE,
      v_descricao,
      v_valor_credito_old,
      'E',
      v_operador,
      NULL);
   
   END IF;
   --
   IF v_valor_credito > 0
   THEN
    -- a agencia usa o credito junto ao fornecedor (movimento de saida)
    v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      p_fornecedor_id,
      SYSDATE,
      v_descricao,
      v_valor_credito,
      'S',
      v_operador,
      NULL);
   
   END IF;
  
  END IF;
  --
  IF v_status_ca = 'REPROV' OR (v_status_ca = 'EMEMIS' AND v_flag_com_aprov = 'S')
  THEN
   -- volta para Em Aprovacao
   UPDATE carta_acordo
      SET status         = 'EMAPRO',
          comentario     = NULL,
          data_aprovacao = NULL,
          faixa_aprov_id = NULL
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  -- limpa eventual fluxo instanciado
  DELETE FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, v_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    v_xml_antes_fo,
                    v_xml_atual_fo,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 PROCEDURE monojob_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/12/2014
  -- DESCRICAO: Atualizacao de CARTA_ACORDO monojob com produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            26/12/2016  Sempre limpa a tabela carta_fluxo_aprov
  -- Silvia            18/06/2018  Novo parametro produto_fiscal_id.
  -- Silvia            30/07/2018  Consistencia de totais aprovados x qtd*freq*unitario
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Silvia            29/09/2020  Indicacao de sobras
  -- Ana Luiza         08/04/2025  Trativa para so verificar valores se flag_pago_cliente = 'S'
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_carta_acordo_id         IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_valor_fornecedor  IN VARCHAR2,
  p_vetor_valor_aprovado    IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_job_id                  job.job_id%TYPE;
  v_num_job                 job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_flag_bloq_negoc         job.flag_bloq_negoc%TYPE;
  v_item_id                 item.item_id%TYPE;
  v_valor_aprovado_it       item.valor_aprovado%TYPE;
  v_orcamento_id            item.orcamento_id%TYPE;
  v_tipo_item_ori           VARCHAR2(10);
  v_tipo_item               VARCHAR2(10);
  v_tipo_item_ant           VARCHAR2(10);
  v_flag_pago_cliente       item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant   item.flag_pago_cliente%TYPE;
  v_nome_item               VARCHAR2(200);
  v_valor_aprovado          carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor        carta_acordo.valor_fornecedor%TYPE;
  v_valor_fornec_aux        carta_acordo.valor_fornecedor%TYPE;
  v_valor_aprovado_ca       carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca     carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv                 carta_acordo.perc_bv%TYPE;
  v_perc_imposto            carta_acordo.perc_imposto%TYPE;
  v_num_carta_formatado     carta_acordo.num_carta_formatado%TYPE;
  v_tipo_fatur_bv           carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr             carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr        carta_acordo.perc_imposto_pdr%TYPE;
  v_valor_credito           carta_acordo.valor_credito_usado%TYPE;
  v_valor_credito_old       carta_acordo.valor_credito_usado%TYPE;
  v_status_ca               carta_acordo.status%TYPE;
  v_flag_mostrar_ac         carta_acordo.flag_mostrar_ac%TYPE;
  v_fornecedor_old_id       carta_acordo.fornecedor_id%TYPE;
  v_contato_fornec          carta_acordo.contato_fornec%TYPE;
  v_flag_com_aprov          carta_acordo.flag_com_aprov%TYPE;
  v_operador                lancamento.operador%TYPE;
  v_descricao               lancamento.descricao%TYPE;
  v_fornecedor              pessoa.apelido%TYPE;
  v_tipo_produto_id         tipo_produto.tipo_produto_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_parc_datas        LONG;
  v_vetor_parc_valores      LONG;
  v_vetor_parc_num_dias     LONG;
  v_vetor_item_id           LONG;
  v_vetor_tipo_produto_id   LONG;
  v_vetor_produto_fiscal_id LONG;
  v_vetor_quantidade        LONG;
  v_vetor_frequencia        LONG;
  v_vetor_custo_unitario    LONG;
  v_vetor_complemento       LONG;
  v_vetor_valor_aprovado    LONG;
  v_vetor_valor_fornecedor  LONG;
  v_vetor_sobra_valores     LONG;
  v_vetor_sobra_item_id     LONG;
  v_data_parcela_char       VARCHAR2(50);
  v_valor_parcela_char      VARCHAR2(50);
  v_num_dias_char           VARCHAR2(50);
  v_quantidade_char         VARCHAR2(50);
  v_frequencia_char         VARCHAR2(50);
  v_valor_aprovado_char     VARCHAR2(50);
  v_valor_fornecedor_char   VARCHAR2(50);
  v_custo_unitario_char     VARCHAR2(50);
  v_valor_sobra_char        VARCHAR2(50);
  v_complemento             VARCHAR2(32000);
  v_sobra_id                sobra.sobra_id%TYPE;
  v_valor_sobra             item_sobra.valor_sobra_item%TYPE;
  v_quantidade              item_carta.quantidade%TYPE;
  v_frequencia              item_carta.frequencia%TYPE;
  v_custo_unitario          item_carta.custo_unitario%TYPE;
  v_produto_fiscal_id       item_carta.produto_fiscal_id%TYPE;
  v_data_parcela            parcela_carta.data_parcela%TYPE;
  v_valor_parcela           parcela_carta.valor_parcela%TYPE;
  v_num_dias                parcela_carta.num_dias%TYPE;
  v_num_dias_ant            parcela_carta.num_dias%TYPE;
  v_parcela_carta_id        parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela             parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant        parcela_carta.data_parcela%TYPE;
  v_valor_acumulado         NUMBER;
  v_tipo_data               VARCHAR2(10);
  v_tipo_data_ant           VARCHAR2(10);
  v_xml_doc                 VARCHAR2(100);
  v_xml_entrega             xmltype;
  v_xml_montagem            xmltype;
  v_xml_prest_servico       xmltype;
  v_xml_desmontagem         xmltype;
  v_xml_evento              xmltype;
  v_xml_corpo               xmltype;
  v_xml_carta               VARCHAR2(4000);
  v_valor_disponivel        NUMBER;
  v_valor_liberado_b        NUMBER;
  v_lbl_job                 VARCHAR2(100);
  v_flag_bv_faturar         VARCHAR2(20);
  v_flag_bv_abater          VARCHAR2(20);
  v_flag_bv_creditar        VARCHAR2(20);
  v_flag_bv_permutar        VARCHAR2(20);
  v_flag_pgto_manual        VARCHAR2(20);
  v_flag_pgto_tabela        VARCHAR2(20);
  v_flag_com_forma_pag      VARCHAR2(20);
  v_flag_prod_fiscal        VARCHAR2(20);
  v_local_parcelam_fornec   VARCHAR2(50);
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  v_xml_antes_fo            CLOB;
  v_xml_atual_fo            CLOB;
  --
  CURSOR c_it IS
   SELECT DISTINCT item_id
     FROM item_carta
    WHERE carta_acordo_id = p_carta_acordo_id;
  --
  CURSOR c_is IS
   SELECT io.item_sobra_id,
          io.item_id
     FROM sobra      so,
          item_sobra io
    WHERE so.carta_acordo_id = p_carta_acordo_id
      AND so.sobra_id = io.sobra_id;
  --
  -- cursor para consistir totais aprovados x qtd*freq*unitario
  -- (apenas o primeiro registro encontrado)
  CURSOR c_va IS
   SELECT TRIM(v.nome || ' ' || v.complemento) AS produto,
          v.valor_calculado,
          v.valor_lancado
     FROM (SELECT tp.nome,
                  ic.complemento,
                  nvl(round(ic.quantidade * ic.frequencia * ic.custo_unitario, 2), 0) AS valor_calculado,
                  nvl(SUM(ic.valor_aprovado), 0) AS valor_lancado
             FROM item_carta   ic,
                  tipo_produto tp
            WHERE ic.carta_acordo_id = p_carta_acordo_id
              AND ic.tipo_produto_id = tp.tipo_produto_id
            GROUP BY ic.tipo_produto_id,
                     tp.nome,
                     ic.complemento,
                     ic.quantidade,
                     ic.frequencia,
                     ic.custo_unitario,
                     nvl(ic.produto_fiscal_id, 0)
           HAVING nvl(round(ic.quantidade * ic.frequencia * ic.custo_unitario, 2), 0) <> nvl(SUM(ic.valor_aprovado), 0)) v
    WHERE rownum = 1;
  --
 BEGIN
  v_qt                    := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_flag_prod_fiscal      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COM_PRODUTO_FISCAL');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         ca.flag_com_aprov,
         jo.numero,
         jo.status,
         jo.flag_bloq_negoc,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv_pdr, 0),
         nvl(ca.perc_imposto_pdr, 0),
         nvl(ca.valor_credito_usado, 0),
         ca.fornecedor_id
    INTO v_job_id,
         v_status_ca,
         v_flag_com_aprov,
         v_num_job,
         v_status_job,
         v_flag_bloq_negoc,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_valor_credito_old,
         v_fornecedor_old_id
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF v_status_ca = 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não pode ser alterada pois já foi emitida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_fornecedor
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id;
  --
  IF nvl(p_contato_fornec_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_filho_id = p_contato_fornec_id
     AND pessoa_pai_id = p_fornecedor_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_contato_fornec
    FROM pessoa
   WHERE pessoa_id = p_contato_fornec_id;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET fornecedor_id       = p_fornecedor_id,
         contato_fornec_id   = p_contato_fornec_id,
         contato_fornec      = v_contato_fornec,
         cliente_id          = p_cliente_id,
         emp_faturar_por_id  = p_emp_faturar_por_id,
         condicao_pagto_id   = zvl(p_condicao_pagto_id, NULL),
         modo_pagto          = TRIM(p_modo_pagto),
         fi_banco_fornec_id  = zvl(p_emp_fi_banco_id, NULL),
         num_agencia         = TRIM(p_emp_num_agencia),
         num_conta           = TRIM(p_emp_num_conta),
         tipo_conta          = TRIM(p_emp_tipo_conta),
         desc_item           = TRIM(p_desc_item),
         instr_especiais     = TRIM(p_instr_especiais),
         valor_aprovado      = 0,
         valor_fornecedor    = 0,
         perc_bv             = v_perc_bv,
         motivo_atu_bv       = TRIM(p_motivo_atu_bv),
         perc_imposto        = v_perc_imposto,
         motivo_atu_imp      = TRIM(p_motivo_atu_imp),
         tipo_fatur_bv       = v_tipo_fatur_bv,
         produtor_id         = p_produtor_id,
         texto_xml           = v_xml_carta,
         valor_credito_usado = v_valor_credito,
         cod_ext_carta       = TRIM(p_cod_ext_carta)
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   DELETE FROM item_carta
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = r_it.item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  v_tipo_item_ant         := NULL;
  v_flag_pago_cliente_ant := NULL;
  --
  v_delimitador         := '|';
  v_valor_aprovado_ca   := 0;
  v_valor_fornecedor_ca := 0;
  --
  v_vetor_item_id           := p_vetor_item_id;
  v_vetor_quantidade        := p_vetor_quantidade;
  v_vetor_frequencia        := p_vetor_frequencia;
  v_vetor_custo_unitario    := p_vetor_custo_unitario;
  v_vetor_complemento       := p_vetor_complemento;
  v_vetor_tipo_produto_id   := p_vetor_tipo_produto_id;
  v_vetor_valor_aprovado    := p_vetor_valor_aprovado;
  v_vetor_valor_fornecedor  := p_vetor_valor_fornecedor;
  v_vetor_produto_fiscal_id := p_vetor_produto_fiscal_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id               := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_tipo_produto_id       := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_quantidade_char       := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char       := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char   := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento           := TRIM(prox_valor_retornar(v_vetor_complemento, v_delimitador));
   v_valor_fornecedor_char := TRIM(prox_valor_retornar(v_vetor_valor_fornecedor, v_delimitador));
   v_valor_aprovado_char   := TRIM(prox_valor_retornar(v_vetor_valor_aprovado, v_delimitador));
   v_produto_fiscal_id     := to_number(prox_valor_retornar(v_vetor_produto_fiscal_id,
                                                            v_delimitador));
   --
   SELECT MAX(job_id),
          MAX(orcamento_id)
     INTO v_job_id,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE tipo_produto_id = nvl(v_tipo_produto_id, -1)
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse entregável não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_prod_fiscal = 'S' AND nvl(v_produto_fiscal_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do produto fiscal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_produto_fiscal_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_fiscal
     WHERE produto_fiscal_id = v_produto_fiscal_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse produto fiscal não existe ou não pertence a essa empresa (' ||
                   to_char(v_produto_fiscal_id) || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   SELECT jo.numero,
          jo.status,
          jo.flag_bloq_negoc
     INTO v_num_job,
          v_status_job,
          v_flag_bloq_negoc
     FROM job jo
    WHERE jo.job_id = v_job_id;
   --
   IF v_status_ca = 'REPROV'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_C',
                                  v_orcamento_id,
                                  NULL,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSE
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_A',
                                  v_orcamento_id,
                                  NULL,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O status do ' || v_lbl_job || ' ' || v_num_job || ' não permite essa operação.';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_item,
          flag_pago_cliente
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_tipo_item,
          v_tipo_item_ori,
          v_flag_pago_cliente
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma carta acordo com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido (' ||
                  v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma carta acordo.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF numero_validar(v_custo_unitario_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_quantidade_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_frequencia_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_fornecedor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_aprovado_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_unitario   := nvl(numero_converter(v_custo_unitario_char), 0);
   v_quantidade       := nvl(numero_converter(v_quantidade_char), 0);
   v_frequencia       := nvl(numero_converter(v_frequencia_char), 0);
   v_valor_aprovado   := nvl(moeda_converter(v_valor_aprovado_char), 0);
   v_valor_fornecedor := nvl(moeda_converter(v_valor_fornecedor_char), 0);
   --
   IF v_valor_aprovado < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo do fornecedor inválido (' || v_nome_item || ': ' ||
                  moeda_mostrar(v_valor_fornecedor, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor > v_valor_aprovado
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O custo do fornecedor não pode ser maior que o valor aprovado (' || v_nome_item || ': ' ||
                  moeda_mostrar(v_valor_fornecedor, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o valor orçado (' ||
                  moeda_mostrar(v_valor_aprovado_it, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ori = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                   moeda_mostrar(v_valor_aprovado, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_aprovado > v_valor_disponivel
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > 0 OR v_valor_fornecedor > 0
   THEN
    INSERT INTO item_carta
     (item_carta_id,
      carta_acordo_id,
      item_id,
      tipo_produto_id,
      valor_aprovado,
      valor_fornecedor,
      custo_unitario,
      quantidade,
      frequencia,
      complemento,
      produto_fiscal_id)
    VALUES
     (seq_item_carta.nextval,
      p_carta_acordo_id,
      v_item_id,
      v_tipo_produto_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      v_custo_unitario,
      v_quantidade,
      v_frequencia,
      v_complemento,
      zvl(v_produto_fiscal_id, NULL));
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    v_valor_aprovado_ca   := v_valor_aprovado_ca + v_valor_aprovado;
    v_valor_fornecedor_ca := v_valor_fornecedor_ca + v_valor_fornecedor;
   END IF;
   --
   -- trata status do job
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais e atualizacao da carta acordo
  ------------------------------------------------------------
  --
  IF v_valor_aprovado_ca = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor foi informado para os itens dessa carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo total do fornecedor (' || moeda_mostrar(v_valor_fornecedor_ca, 'S') ||
                 ') não pode ser maior que o valor total aprovado pelo cliente (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF TRIM(p_perc_imposto) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   UPDATE carta_acordo
      SET perc_imposto = 0
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
    INTO v_flag_pago_cliente
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = p_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_flag_mostrar_ac := 'N';
  ELSE
   v_flag_mostrar_ac := 'S';
  END IF;
  --
  UPDATE carta_acordo
     SET valor_aprovado   = v_valor_aprovado_ca,
         valor_fornecedor = v_valor_fornecedor_ca,
         flag_mostrar_ac  = v_flag_mostrar_ac
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- consistencias de item_carta
  ------------------------------------------------------------
  -- verificacao de valores aprovados X qtd*freq*unitario
  --ALCBO_080425
  IF v_flag_pago_cliente = 'S'
  THEN
   FOR r_va IN c_va
   LOOP
    p_erro_cod := '90000';
    p_erro_msg := 'O entregável "' || r_va.produto || '" apresenta o valor ' ||
                  'R$ Forcecedor (qtd X freq X unitário) diferente da somatória dos Valores da Nota lançados (' ||
                  'R$ Forcecedor: ' || moeda_mostrar(r_va.valor_calculado, 'S') ||
                  ' ; Valores da Nota: ' || moeda_mostrar(r_va.valor_lancado, 'S') || ')';
   
    RAISE v_exception;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (excusao das sobras)
  ------------------------------------------------------------
  FOR r_is IN c_is
  LOOP
   DELETE FROM item_sobra
    WHERE item_sobra_id = r_is.item_sobra_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_is.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM sobra so
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de sobras
  ------------------------------------------------------------
  v_delimitador := '|';
  v_sobra_id    := NULL;
  --
  v_vetor_sobra_item_id := p_vetor_sobra_item_id;
  v_vetor_sobra_valores := p_vetor_sobra_valores;
  --
  WHILE nvl(length(rtrim(v_vetor_sobra_item_id)), 0) > 0
  LOOP
   v_item_id          := to_number(prox_valor_retornar(v_vetor_sobra_item_id, v_delimitador));
   v_valor_sobra_char := prox_valor_retornar(v_vetor_sobra_valores, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item inválido no vetor de sobras (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          job_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_job_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF moeda_validar(v_valor_sobra_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_sobra := nvl(moeda_converter(v_valor_sobra_char), 0);
   --
   IF v_valor_sobra < 0 OR v_valor_sobra > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_sobra > 0
   THEN
    SELECT MAX(sobra_id)
      INTO v_sobra_id
      FROM sobra
     WHERE job_id = v_job_id
       AND carta_acordo_id = p_carta_acordo_id;
    --
    IF v_sobra_id IS NULL
    THEN
     SELECT seq_sobra.nextval
       INTO v_sobra_id
       FROM dual;
     --
     INSERT INTO sobra
      (sobra_id,
       job_id,
       carta_acordo_id,
       usuario_resp_id,
       data_entrada,
       tipo_sobra,
       justificativa,
       valor_sobra,
       valor_cred_cliente,
       flag_dentro_ca)
     VALUES
      (v_sobra_id,
       v_job_id,
       p_carta_acordo_id,
       p_usuario_sessao_id,
       SYSDATE,
       'SOB',
       NULL,
       0,
       0,
       'N');
    
    END IF;
    --
    INSERT INTO item_sobra
     (item_sobra_id,
      item_id,
      sobra_id,
      valor_sobra_item,
      valor_cred_item,
      flag_abate_fatur)
    VALUES
     (seq_item_sobra.nextval,
      v_item_id,
      v_sobra_id,
      v_valor_sobra,
      0,
      'N');
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF; -- fim do IF v_valor_sobra > 0
  END LOOP;
  --
  UPDATE sobra so
     SET valor_sobra =
         (SELECT nvl(SUM(valor_sobra_item), 0)
            FROM item_sobra it
           WHERE it.sobra_id = so.sobra_id)
   WHERE so.carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  DELETE FROM parcela_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       p_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito <> v_valor_credito_old OR p_fornecedor_id <> v_fornecedor_old_id
  THEN
   -- valor do credito ou fornecedor alterados
   IF v_valor_credito_old > 0
   THEN
    -- estorno do uso do credito pela agencia junto ao fornecedor (movimento de entrada)
    v_descricao := 'Estorno do uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      v_fornecedor_old_id,
      SYSDATE,
      v_descricao,
      v_valor_credito_old,
      'E',
      v_operador,
      NULL);
   
   END IF;
   --
   IF v_valor_credito > 0
   THEN
    -- a agencia usa o credito junto ao fornecedor (movimento de saida)
    v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      p_fornecedor_id,
      SYSDATE,
      v_descricao,
      v_valor_credito,
      'S',
      v_operador,
      NULL);
   
   END IF;
  
  END IF;
  --
  IF v_status_ca = 'REPROV' OR (v_status_ca = 'EMEMIS' AND v_flag_com_aprov = 'S')
  THEN
   -- volta para Em Aprovacao
   UPDATE carta_acordo
      SET status         = 'EMAPRO',
          comentario     = NULL,
          data_aprovacao = NULL,
          faixa_aprov_id = NULL
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  -- limpa eventual fluxo instanciado
  DELETE FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    v_xml_antes_fo,
                    v_xml_atual_fo,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END monojob_atualizar;
 --
 --
 PROCEDURE multijob_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 24/10/2013
  -- DESCRICAO: Atualizacao de CARTA_ACORDO multijob com produtos comprados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  -- Silvia            22/05/2015  Novos atributos de dados bancarios
  -- Silvia            26/12/2016  Sempre limpa a tabela carta_fluxo_aprov
  -- Silvia            18/06/2018  Novo parametro produto_fiscal_id.
  -- Silvia            01/11/2019  Novo parametro cod_ext_carta
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Silvia            29/09/2020  Indicacao de sobras
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_carta_acordo_id         IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_job_id                  job.job_id%TYPE;
  v_num_job                 job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_flag_bloq_negoc         job.flag_bloq_negoc%TYPE;
  v_item_id                 item.item_id%TYPE;
  v_valor_aprovado_it       item.valor_aprovado%TYPE;
  v_orcamento_id            item.orcamento_id%TYPE;
  v_tipo_item_ori           VARCHAR2(10);
  v_tipo_item               VARCHAR2(10);
  v_tipo_item_ant           VARCHAR2(10);
  v_flag_pago_cliente       item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant   item.flag_pago_cliente%TYPE;
  v_nome_item               VARCHAR2(200);
  v_valor_aprovado          carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor        carta_acordo.valor_fornecedor%TYPE;
  v_valor_aprovado_ca       carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca     carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv                 carta_acordo.perc_bv%TYPE;
  v_perc_imposto            carta_acordo.perc_imposto%TYPE;
  v_num_carta_formatado     carta_acordo.num_carta_formatado%TYPE;
  v_tipo_fatur_bv           carta_acordo.tipo_fatur_bv%TYPE;
  v_perc_bv_pdr             carta_acordo.perc_bv_pdr%TYPE;
  v_perc_imposto_pdr        carta_acordo.perc_imposto_pdr%TYPE;
  v_valor_credito           carta_acordo.valor_credito_usado%TYPE;
  v_valor_credito_old       carta_acordo.valor_credito_usado%TYPE;
  v_status_ca               carta_acordo.status%TYPE;
  v_flag_mostrar_ac         carta_acordo.flag_mostrar_ac%TYPE;
  v_fornecedor_old_id       carta_acordo.fornecedor_id%TYPE;
  v_contato_fornec          carta_acordo.contato_fornec%TYPE;
  v_flag_com_aprov          carta_acordo.flag_com_aprov%TYPE;
  v_operador                lancamento.operador%TYPE;
  v_descricao               lancamento.descricao%TYPE;
  v_fornecedor              pessoa.apelido%TYPE;
  v_tipo_produto_id         tipo_produto.tipo_produto_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_parc_datas        LONG;
  v_vetor_parc_valores      LONG;
  v_vetor_parc_num_dias     LONG;
  v_vetor_item_id           LONG;
  v_vetor_tipo_produto_id   LONG;
  v_vetor_produto_fiscal_id LONG;
  v_vetor_quantidade        LONG;
  v_vetor_frequencia        LONG;
  v_vetor_custo_unitario    LONG;
  v_vetor_complemento       LONG;
  v_vetor_sobra_valores     LONG;
  v_vetor_sobra_item_id     LONG;
  v_data_parcela_char       VARCHAR2(50);
  v_valor_parcela_char      VARCHAR2(50);
  v_num_dias_char           VARCHAR2(50);
  v_quantidade_char         VARCHAR2(50);
  v_frequencia_char         VARCHAR2(50);
  v_custo_unitario_char     VARCHAR2(50);
  v_valor_sobra_char        VARCHAR2(50);
  v_complemento             VARCHAR2(32000);
  v_sobra_id                sobra.sobra_id%TYPE;
  v_valor_sobra             item_sobra.valor_sobra_item%TYPE;
  v_quantidade              item_carta.quantidade%TYPE;
  v_frequencia              item_carta.frequencia%TYPE;
  v_custo_unitario          item_carta.custo_unitario%TYPE;
  v_produto_fiscal_id       item_carta.produto_fiscal_id%TYPE;
  v_data_parcela            parcela_carta.data_parcela%TYPE;
  v_valor_parcela           parcela_carta.valor_parcela%TYPE;
  v_num_dias                parcela_carta.num_dias%TYPE;
  v_num_dias_ant            parcela_carta.num_dias%TYPE;
  v_parcela_carta_id        parcela_carta.parcela_carta_id%TYPE;
  v_num_parcela             parcela_carta.num_parcela%TYPE;
  v_data_parcela_ant        parcela_carta.data_parcela%TYPE;
  v_valor_acumulado         NUMBER;
  v_tipo_data               VARCHAR2(10);
  v_tipo_data_ant           VARCHAR2(10);
  v_xml_doc                 VARCHAR2(100);
  v_xml_entrega             xmltype;
  v_xml_montagem            xmltype;
  v_xml_prest_servico       xmltype;
  v_xml_desmontagem         xmltype;
  v_xml_evento              xmltype;
  v_xml_corpo               xmltype;
  v_xml_carta               VARCHAR2(4000);
  v_valor_disponivel        NUMBER;
  v_valor_liberado_b        NUMBER;
  v_lbl_job                 VARCHAR2(100);
  v_flag_bv_faturar         VARCHAR2(20);
  v_flag_bv_abater          VARCHAR2(20);
  v_flag_bv_creditar        VARCHAR2(20);
  v_flag_bv_permutar        VARCHAR2(20);
  v_flag_pgto_manual        VARCHAR2(20);
  v_flag_pgto_tabela        VARCHAR2(20);
  v_flag_com_forma_pag      VARCHAR2(20);
  v_flag_prod_fiscal        VARCHAR2(20);
  v_local_parcelam_fornec   VARCHAR2(50);
  v_xml_antes               CLOB;
  v_xml_atual               CLOB;
  v_xml_antes_fo            CLOB;
  v_xml_atual_fo            CLOB;
  --
  CURSOR c_it IS
   SELECT DISTINCT item_id
     FROM item_carta
    WHERE carta_acordo_id = p_carta_acordo_id;
  --
  CURSOR c_is IS
   SELECT io.item_sobra_id,
          io.item_id
     FROM sobra      so,
          item_sobra io
    WHERE so.carta_acordo_id = p_carta_acordo_id
      AND so.sobra_id = io.sobra_id;
  --
 BEGIN
  v_qt                    := 0;
  v_lbl_job               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_bv_faturar       := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater        := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  v_flag_pgto_manual      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_MANUAL');
  v_flag_pgto_tabela      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COND_PGTO_TABELADA');
  v_flag_com_forma_pag    := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_OBRIGA_FORMA_PAGTO');
  v_flag_prod_fiscal      := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_COM_PRODUTO_FISCAL');
  v_local_parcelam_fornec := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         ca.flag_com_aprov,
         jo.numero,
         jo.status,
         jo.flag_bloq_negoc,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv_pdr, 0),
         nvl(ca.perc_imposto_pdr, 0),
         nvl(ca.valor_credito_usado, 0),
         ca.fornecedor_id
    INTO v_job_id,
         v_status_ca,
         v_flag_com_aprov,
         v_num_job,
         v_status_job,
         v_flag_bloq_negoc,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv_pdr,
         v_perc_imposto_pdr,
         v_valor_credito_old,
         v_fornecedor_old_id
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF v_status_ca = 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não pode ser alterada pois já foi emitida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_cod_ext_carta)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo da carta acordo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_fornecedor
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id;
  --
  IF nvl(p_contato_fornec_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_filho_id = p_contato_fornec_id
     AND pessoa_pai_id = p_fornecedor_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contato não existe ou não está relacionado a esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_contato_fornec
    FROM pessoa
   WHERE pessoa_id = p_contato_fornec_id;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_item) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do item não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_credito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito := nvl(moeda_converter(p_valor_credito), 0);
  --
  IF v_valor_credito < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito inválido (' || p_valor_credito || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_perc_bv      := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_flag_com_forma_pag = 'S' AND TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação da forma de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NOT NULL AND util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de pagamento inválida (' || p_modo_pagto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instr_especiais) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das instruções especiais não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de entrega
  IF data_validar(p_entre_data_prototipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do protótipo inválida (' || p_entre_data_prototipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_entre_data_produto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrega do produto inválida (' || p_entre_data_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_entre_local) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do local de entrega não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de montagem
  IF hora_validar(p_monta_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da montagem inválida (' || p_monta_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da montagem inválida (' || p_monta_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_monta_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da montagem inválida (' || p_monta_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_monta_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da montagem inválida (' || p_monta_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de prestacao de servico
  IF hora_validar(p_pserv_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da prestação de serviço inválida (' || p_pserv_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da prestação de serviço inválida (' || p_pserv_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_pserv_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da prestação de serviço inválida (' || p_pserv_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_pserv_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da prestação de serviço inválida (' || p_pserv_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de desmontagem
  IF hora_validar(p_desmo_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início da desmontagem inválida (' || p_desmo_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início da desmontagem inválida (' || p_desmo_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_desmo_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término da desmontagem inválida (' || p_desmo_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_desmo_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término da desmontagem inválida (' || p_desmo_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias de evento
  IF hora_validar(p_event_hora_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início do evento inválida (' || p_event_hora_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início do evento inválida (' || p_event_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_event_hora_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término do evento inválida (' || p_event_hora_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_event_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término do evento inválida (' || p_event_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produtor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_imp) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do Imposto Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_atu_bv) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa para alteração do BV Padrão ' ||
                 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- montagem do XML
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT xmlagg(xmlelement("entrega",
                           xmlelement("data_prototipo",
                                      data_mostrar(data_converter(p_entre_data_prototipo))),
                           xmlelement("data_produto",
                                      data_mostrar(data_converter(p_entre_data_produto))),
                           xmlelement("local", p_entre_local)))
    INTO v_xml_entrega
    FROM dual;
  --
  SELECT xmlagg(xmlelement("montagem",
                           xmlelement("hora_inicio", p_monta_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_monta_data_ini))),
                           xmlelement("hora_fim", p_monta_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_monta_data_fim)))))
    INTO v_xml_montagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("prest_servico",
                           xmlelement("hora_inicio", p_pserv_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_pserv_data_ini))),
                           xmlelement("hora_fim", p_pserv_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_pserv_data_fim)))))
    INTO v_xml_prest_servico
    FROM dual;
  --
  SELECT xmlagg(xmlelement("desmontagem",
                           xmlelement("hora_inicio", p_desmo_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_desmo_data_ini))),
                           xmlelement("hora_fim", p_desmo_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_desmo_data_fim)))))
    INTO v_xml_desmontagem
    FROM dual;
  --
  SELECT xmlagg(xmlelement("evento",
                           xmlelement("descricao", p_event_desc),
                           xmlelement("local", p_event_local),
                           xmlelement("hora_inicio", p_event_hora_ini),
                           xmlelement("data_inicio", data_mostrar(data_converter(p_event_data_ini))),
                           xmlelement("hora_fim", p_event_hora_fim),
                           xmlelement("data_fim", data_mostrar(data_converter(p_event_data_fim)))))
    INTO v_xml_evento
    FROM dual;
  --
  -- junta tudo debaixo de conteudo
  SELECT xmlagg(xmlelement("conteudo",
                           v_xml_entrega,
                           v_xml_montagem,
                           v_xml_prest_servico,
                           v_xml_desmontagem,
                           v_xml_evento))
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT v_xml_doc || v_xml_corpo.getclobval()
    INTO v_xml_carta
    FROM dual;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET fornecedor_id       = p_fornecedor_id,
         contato_fornec_id   = p_contato_fornec_id,
         contato_fornec      = v_contato_fornec,
         cliente_id          = p_cliente_id,
         emp_faturar_por_id  = p_emp_faturar_por_id,
         condicao_pagto_id   = zvl(p_condicao_pagto_id, NULL),
         modo_pagto          = TRIM(p_modo_pagto),
         fi_banco_fornec_id  = zvl(p_emp_fi_banco_id, NULL),
         num_agencia         = TRIM(p_emp_num_agencia),
         num_conta           = TRIM(p_emp_num_conta),
         tipo_conta          = TRIM(p_emp_tipo_conta),
         desc_item           = TRIM(p_desc_item),
         instr_especiais     = TRIM(p_instr_especiais),
         valor_aprovado      = 0,
         valor_fornecedor    = 0,
         perc_bv             = v_perc_bv,
         motivo_atu_bv       = TRIM(p_motivo_atu_bv),
         perc_imposto        = v_perc_imposto,
         motivo_atu_imp      = TRIM(p_motivo_atu_imp),
         tipo_fatur_bv       = v_tipo_fatur_bv,
         produtor_id         = p_produtor_id,
         texto_xml           = v_xml_carta,
         valor_credito_usado = v_valor_credito,
         cod_ext_carta       = TRIM(p_cod_ext_carta)
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   DELETE FROM item_carta
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = r_it.item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  v_tipo_item_ant         := NULL;
  v_flag_pago_cliente_ant := NULL;
  --
  v_delimitador         := '|';
  v_valor_aprovado_ca   := 0;
  v_valor_fornecedor_ca := 0;
  --
  v_vetor_item_id           := p_vetor_item_id;
  v_vetor_quantidade        := p_vetor_quantidade;
  v_vetor_frequencia        := p_vetor_frequencia;
  v_vetor_custo_unitario    := p_vetor_custo_unitario;
  v_vetor_complemento       := p_vetor_complemento;
  v_vetor_tipo_produto_id   := p_vetor_tipo_produto_id;
  v_vetor_produto_fiscal_id := p_vetor_produto_fiscal_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id             := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_tipo_produto_id     := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_quantidade_char     := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char     := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento         := TRIM(prox_valor_retornar(v_vetor_complemento, v_delimitador));
   v_produto_fiscal_id   := to_number(prox_valor_retornar(v_vetor_produto_fiscal_id, v_delimitador));
   --
   SELECT MAX(job_id),
          MAX(orcamento_id)
     INTO v_job_id,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE tipo_produto_id = nvl(v_tipo_produto_id, -1)
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse entregável não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_prod_fiscal = 'S' AND nvl(v_produto_fiscal_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do produto fiscal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_produto_fiscal_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_fiscal
     WHERE produto_fiscal_id = v_produto_fiscal_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse produto fiscal não existe ou não pertence a essa empresa (' ||
                   to_char(v_produto_fiscal_id) || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   SELECT jo.numero,
          jo.status,
          jo.flag_bloq_negoc
     INTO v_num_job,
          v_status_job,
          v_flag_bloq_negoc
     FROM job jo
    WHERE jo.job_id = v_job_id;
   --
   IF v_status_ca = 'REPROV'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_C',
                                  NULL,
                                  p_carta_acordo_id,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSE
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_A',
                                  NULL,
                                  p_carta_acordo_id,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O status do ' || v_lbl_job || ' ' || v_num_job || ' não permite essa operação.';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_item,
          flag_pago_cliente
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_tipo_item,
          v_tipo_item_ori,
          v_flag_pago_cliente
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma carta acordo com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido (' ||
                  v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma carta acordo.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF numero_validar(v_custo_unitario_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_quantidade_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_frequencia_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_unitario   := nvl(numero_converter(v_custo_unitario_char), 0);
   v_quantidade       := nvl(numero_converter(v_quantidade_char), 0);
   v_frequencia       := nvl(numero_converter(v_frequencia_char), 0);
   v_valor_aprovado   := round(v_quantidade * v_frequencia * v_custo_unitario, 2);
   v_valor_fornecedor := v_valor_aprovado;
   --
   IF v_valor_aprovado <= 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o valor orçado (' ||
                  moeda_mostrar(v_valor_aprovado_it, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item_ori = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                   moeda_mostrar(v_valor_aprovado, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_aprovado > v_valor_disponivel
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado na carta acordo (' ||
                  moeda_mostrar(v_valor_aprovado, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado > 0 OR v_valor_fornecedor > 0
   THEN
    /*
    SELECT COUNT(*)
      INTO v_qt
      FROM item_carta
     WHERE carta_acordo_id = p_carta_acordo_id
       AND item_id = v_item_id;
    --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O item ' || v_nome_item ||
                     ', não pode ser lançado na carta acordo mais de uma vez.';
       RAISE v_exception;
    END IF;*/
    --
    INSERT INTO item_carta
     (item_carta_id,
      carta_acordo_id,
      item_id,
      tipo_produto_id,
      valor_aprovado,
      valor_fornecedor,
      custo_unitario,
      quantidade,
      frequencia,
      complemento,
      produto_fiscal_id)
    VALUES
     (seq_item_carta.nextval,
      p_carta_acordo_id,
      v_item_id,
      v_tipo_produto_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      v_custo_unitario,
      v_quantidade,
      v_frequencia,
      v_complemento,
      zvl(v_produto_fiscal_id, NULL));
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    v_valor_aprovado_ca   := v_valor_aprovado_ca + v_valor_aprovado;
    v_valor_fornecedor_ca := v_valor_fornecedor_ca + v_valor_fornecedor;
   END IF;
   --
   -- trata status do job
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais e atualizacao da carta acordo
  ------------------------------------------------------------
  --
  IF v_valor_aprovado_ca = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor foi informado para os itens dessa carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo total do fornecedor (' || moeda_mostrar(v_valor_fornecedor_ca, 'S') ||
                 ') não pode ser maior que o valor total aprovado pelo cliente (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_credito > v_valor_aprovado_ca
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O crédito usado (' || moeda_mostrar(v_valor_credito, 'S') ||
                 ') não pode ser maior que o valor total (' ||
                 moeda_mostrar(v_valor_aprovado_ca, 'S') || ').';
  
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor_ca <> v_valor_aprovado_ca
  THEN
   IF TRIM(p_perc_imposto) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto_pdr <> v_perc_imposto AND TRIM(p_motivo_atu_imp) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário justificar a mudança do percentual de imposto do fornecedor';
    RAISE v_exception;
   END IF;
  
  ELSE
   -- despreza o percentual informado (valor_fornecedor = valor_aprovado)
   UPDATE carta_acordo
      SET perc_imposto = 0
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_perc_bv_pdr <> v_perc_bv AND TRIM(p_motivo_atu_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar a mudança do percentual de BV do fornecedor';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ca = v_valor_fornecedor_ca) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_ca = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ca <> v_valor_fornecedor_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
    INTO v_flag_pago_cliente
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = p_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_flag_mostrar_ac := 'N';
  ELSE
   v_flag_mostrar_ac := 'S';
  END IF;
  --
  UPDATE carta_acordo
     SET valor_aprovado   = v_valor_aprovado_ca,
         valor_fornecedor = v_valor_fornecedor_ca,
         flag_mostrar_ac  = v_flag_mostrar_ac
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (excusao das sobras)
  ------------------------------------------------------------
  FOR r_is IN c_is
  LOOP
   DELETE FROM item_sobra
    WHERE item_sobra_id = r_is.item_sobra_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_is.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM sobra so
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de sobras
  ------------------------------------------------------------
  v_delimitador := '|';
  v_sobra_id    := NULL;
  --
  v_vetor_sobra_item_id := p_vetor_sobra_item_id;
  v_vetor_sobra_valores := p_vetor_sobra_valores;
  --
  WHILE nvl(length(rtrim(v_vetor_sobra_item_id)), 0) > 0
  LOOP
   v_item_id          := to_number(prox_valor_retornar(v_vetor_sobra_item_id, v_delimitador));
   v_valor_sobra_char := prox_valor_retornar(v_vetor_sobra_valores, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item inválido no vetor de sobras (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          valor_aprovado,
          job_id
     INTO v_nome_item,
          v_valor_aprovado_it,
          v_job_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF moeda_validar(v_valor_sobra_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_sobra := nvl(moeda_converter(v_valor_sobra_char), 0);
   --
   IF v_valor_sobra < 0 OR v_valor_sobra > v_valor_aprovado_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor da sobra inválido (' || v_valor_sobra_char || ' - ' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_sobra > 0
   THEN
    SELECT MAX(sobra_id)
      INTO v_sobra_id
      FROM sobra
     WHERE job_id = v_job_id
       AND carta_acordo_id = p_carta_acordo_id;
    --
    IF v_sobra_id IS NULL
    THEN
     SELECT seq_sobra.nextval
       INTO v_sobra_id
       FROM dual;
     --
     INSERT INTO sobra
      (sobra_id,
       job_id,
       carta_acordo_id,
       usuario_resp_id,
       data_entrada,
       tipo_sobra,
       justificativa,
       valor_sobra,
       valor_cred_cliente,
       flag_dentro_ca)
     VALUES
      (v_sobra_id,
       v_job_id,
       p_carta_acordo_id,
       p_usuario_sessao_id,
       SYSDATE,
       'SOB',
       NULL,
       0,
       0,
       'N');
    
    END IF;
    --
    INSERT INTO item_sobra
     (item_sobra_id,
      item_id,
      sobra_id,
      valor_sobra_item,
      valor_cred_item,
      flag_abate_fatur)
    VALUES
     (seq_item_sobra.nextval,
      v_item_id,
      v_sobra_id,
      v_valor_sobra,
      0,
      'N');
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF; -- fim do IF v_valor_sobra > 0
  END LOOP;
  --
  UPDATE sobra so
     SET valor_sobra =
         (SELECT nvl(SUM(valor_sobra_item), 0)
            FROM item_sobra it
           WHERE it.sobra_id = so.sobra_id)
   WHERE so.carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de parcelamento
  ------------------------------------------------------------
  DELETE FROM parcela_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF TRIM(p_tipo_num_dias) IS NOT NULL AND p_tipo_num_dias NOT IN ('U', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo do número de dias (úteis ou corridos) inválido (' || p_tipo_num_dias || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pgto_tabela = 'S'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0 AND v_valor_credito < v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_condicao_pagto_id, 0) <> 0 AND v_valor_credito = v_valor_aprovado_ca
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A condição de pagamento não deve ser informada pois não há valor a parcelar.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_valor_credito < v_valor_aprovado_ca AND
     TRIM(p_vetor_parc_datas) IS NULL AND TRIM(p_vetor_parc_num_dias) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma condição de pagamento informada (datas ou número de dias).';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam_fornec = 'CARTA_ACORDO' AND v_flag_pgto_manual = 'S' AND
     v_valor_credito < v_valor_aprovado_ca
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
     
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_carta.nextval
       INTO v_parcela_carta_id
       FROM dual;
     --
     INSERT INTO parcela_carta
      (parcela_carta_id,
       carta_acordo_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_carta_id,
       p_carta_acordo_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    
    END IF;
   
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_aprovado_ca - v_valor_credito
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total menos eventuais créditos usados (' ||
                  moeda_mostrar(v_valor_aprovado_ca - v_valor_credito, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_carta
      SET num_tot_parcelas = v_num_parcela
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_valor_credito <> v_valor_credito_old OR p_fornecedor_id <> v_fornecedor_old_id
  THEN
   -- valor do credito ou fornecedor alterados
   IF v_valor_credito_old > 0
   THEN
    -- estorno do uso do credito pela agencia junto ao fornecedor (movimento de entrada)
    v_descricao := 'Estorno do uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      v_fornecedor_old_id,
      SYSDATE,
      v_descricao,
      v_valor_credito_old,
      'E',
      v_operador,
      NULL);
   
   END IF;
   --
   IF v_valor_credito > 0
   THEN
    -- a agencia usa o credito junto ao fornecedor (movimento de saida)
    v_descricao := 'Uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                   v_num_carta_formatado;
    --
    INSERT INTO lancamento
     (lancamento_id,
      pessoa_id,
      data_lancam,
      descricao,
      valor_lancam,
      tipo_mov,
      operador,
      justificativa)
    VALUES
     (seq_lancamento.nextval,
      p_fornecedor_id,
      SYSDATE,
      v_descricao,
      v_valor_credito,
      'S',
      v_operador,
      NULL);
   
   END IF;
  
  END IF;
  --
  IF v_status_ca = 'REPROV' OR (v_status_ca = 'EMEMIS' AND v_flag_com_aprov = 'S')
  THEN
   -- volta para Em Aprovacao
   UPDATE carta_acordo
      SET status         = 'EMAPRO',
          comentario     = NULL,
          data_aprovacao = NULL,
          faixa_aprov_id = NULL
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  -- limpa eventual fluxo instanciado
  DELETE FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- atualiza dados bancarios do fornecedor
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_antes_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = TRIM(p_emp_num_agencia),
          num_conta   = TRIM(p_emp_num_conta),
          tipo_conta  = TRIM(p_emp_tipo_conta)
    WHERE pessoa_id = p_fornecedor_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_fornecedor_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(p_fornecedor_id, v_xml_atual_fo, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_fornecedor;
   v_compl_histor   := 'Alteração de informações bancárias via carta acordo';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    p_fornecedor_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    v_xml_antes_fo,
                    v_xml_atual_fo,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END multijob_atualizar;
 --
 --
 PROCEDURE emitida_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/04/2007
  -- DESCRICAO: Atualização de CARTA_ACORDO (BV, TIP) ja emitida. Operacao Especial.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  -- Ana Luiza         12/05/2025  Atualizando valor BV antes de cancelar o BV
  -- Ana Luiaz         06/08/2025  
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
  p_valor_fornecedor   IN VARCHAR2,
  p_tipo_fatur_bv      IN carta_acordo.tipo_fatur_bv%TYPE,
  p_perc_bv            IN VARCHAR2,
  p_perc_imposto       IN VARCHAR2,
  p_justificativa      IN VARCHAR2,
  p_vetor_item_nota_id IN VARCHAR2,
  p_vetor_valor_fornec IN VARCHAR2,
  p_vetor_valor_bv     IN VARCHAR2,
  p_vetor_valor_tip    IN VARCHAR2,
  p_historico_id       OUT historico.historico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_job_id               job.job_id%TYPE;
  v_fornecedor           pessoa.apelido%TYPE;
  v_faturamento_id       faturamento.faturamento_id%TYPE;
  v_carta_acordo_id      carta_acordo.carta_acordo_id%TYPE;
  v_num_carta_formatado  carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ori   carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_new carta_acordo.valor_fornecedor%TYPE;
  v_valor_fornecedor_old carta_acordo.valor_fornecedor%TYPE;
  v_valor_fornecedor_aux carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv              carta_acordo.perc_bv%TYPE;
  v_perc_bv_old          carta_acordo.perc_bv%TYPE;
  v_perc_imposto         carta_acordo.perc_imposto%TYPE;
  v_perc_imposto_old     carta_acordo.perc_imposto%TYPE;
  v_tipo_fatur_bv        carta_acordo.tipo_fatur_bv%TYPE;
  v_tipo_fatur_bv_old    carta_acordo.tipo_fatur_bv%TYPE;
  v_status_ca            carta_acordo.status%TYPE;
  v_valor_credito        carta_acordo.valor_credito_usado%TYPE;
  v_valor_bv             NUMBER;
  v_valor_tip            NUMBER;
  v_valor_bv_tip_new     NUMBER;
  v_valor_bv_tip_old     NUMBER;
  --
  v_tem_nf             CHAR(1);
  v_delimitador        CHAR(1);
  v_vetor_item_nota_id VARCHAR2(2000);
  v_vetor_valor_fornec VARCHAR2(2000);
  v_vetor_valor_bv     VARCHAR2(2000);
  v_vetor_valor_tip    VARCHAR2(2000);
  v_item_nota_id       item_nota.item_nota_id%TYPE;
  v_valor_fornec_char  VARCHAR2(20);
  v_valor_bv_char      VARCHAR2(20);
  v_valor_tip_char     VARCHAR2(20);
  v_valor_fornec_it    item_nota.valor_fornecedor%TYPE;
  v_valor_aprov_it     item_nota.valor_aprovado%TYPE;
  v_valor_bv_it        item_nota.valor_bv%TYPE;
  v_valor_tip_it       item_nota.valor_tip%TYPE;
  v_nota_fiscal_id     nota_fiscal.nota_fiscal_id%TYPE;
  v_nota_fiscal_sai_id nota_fiscal.nota_fiscal_id%TYPE;
  v_flag_bv_faturar    VARCHAR2(20);
  v_flag_bv_abater     VARCHAR2(20);
  v_flag_bv_creditar   VARCHAR2(20);
  v_flag_bv_permutar   VARCHAR2(20);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
  -- faturamentos de BV associados a carta acordo que nao tem
  -- nota fiscal de saida (nao faturados).
  CURSOR c_fat IS
   SELECT DISTINCT fa.faturamento_id,
                   it.nota_fiscal_id,
                   it.item_id
     FROM item_fatur  it,
          faturamento fa
    WHERE it.carta_acordo_id = p_carta_acordo_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S'
      AND fa.nota_fiscal_sai_id IS NULL;
  /*
  p_cliente_id,
                          p_contato_cli_id,
                          p_produto_cliente_id,
                          p_data_vencim,
                          p_descricao,
                          p_obs,
  */
  --
  -- NFs associadas a carta acordo que nao tem faturamento de
  -- BV comandado.
  CURSOR c_nf IS
   SELECT DISTINCT nota_fiscal_id
     FROM item_nota io
    WHERE carta_acordo_id = p_carta_acordo_id
      AND NOT EXISTS (SELECT 1
             FROM faturamento fa,
                  item_fatur  ia
            WHERE io.nota_fiscal_id = ia.nota_fiscal_id
              AND ia.faturamento_id = fa.faturamento_id
              AND fa.flag_bv = 'S');
  --
 BEGIN
  v_qt           := 0;
  p_historico_id := 0;
  v_tem_nf       := 'N';
  --
  v_flag_bv_faturar  := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_FATURAR');
  v_flag_bv_abater   := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_ABATER');
  v_flag_bv_creditar := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_CREDITAR');
  v_flag_bv_permutar := empresa_pkg.parametro_retornar(p_empresa_id, 'CA_BV_A_PERMUTAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo ca
   WHERE ca.carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         pe.apelido,
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0),
         ca.tipo_fatur_bv,
         round(nvl(ca.valor_fornecedor, 0) * nvl(ca.perc_bv, 0) / 100, 2) +
         round((nvl(ca.valor_aprovado, 0) - nvl(ca.valor_fornecedor, 0)) *
               (1 - nvl(ca.perc_imposto, 0) / 100),
               2),
         nvl(ca.valor_credito_usado, 0)
    INTO v_job_id,
         v_status_ca,
         v_num_carta_formatado,
         v_valor_aprovado_ori,
         v_valor_fornecedor_old,
         v_fornecedor,
         v_perc_bv_old,
         v_perc_imposto_old,
         v_tipo_fatur_bv_old,
         v_valor_bv_tip_old,
         v_valor_credito
    FROM carta_acordo ca,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.fornecedor_id = pe.pessoa_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_justificativa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da justificativa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt > 0
  THEN
   v_tem_nf := 'S';
  END IF;
  --
  IF v_tipo_fatur_bv_old = 'PER' OR v_valor_credito > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Carta acordo com permuta ou crédito usado não pode ser alterada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF moeda_validar(p_valor_fornecedor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo do fornecedor inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF v_tipo_fatur_bv = 'FAT' AND v_flag_bv_faturar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a faturar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA' AND v_flag_bv_abater = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a abater não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'CRE' AND v_flag_bv_creditar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a creditar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER' AND v_flag_bv_permutar = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'BV a permutar não está habilitado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_perc_imposto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de imposto do fornecedor não foi especificado';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_fornecedor_new := nvl(moeda_converter(p_valor_fornecedor), 0);
  v_perc_bv              := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto         := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_valor_fornecedor_new > v_valor_aprovado_ori
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser maior que o valor aprovado.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'ABA'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id
      AND it.flag_pago_cliente = 'S';
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_tipo_fatur_bv = 'NA' AND ((v_valor_aprovado_ori > v_valor_fornecedor_new) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_new <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv <> 'NA' AND ((v_valor_aprovado_ori = v_valor_fornecedor_new) AND
     (v_perc_bv = 0 OR v_valor_fornecedor_new = 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de faturamento especificado para o BV/TIP não se aplica a essa carta.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   IF v_valor_credito > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter crédito usado.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta deve ter 100% de BV.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado_ori <> v_valor_fornecedor_new
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Carta acordo com permuta não pode ter TIP.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET perc_bv          = v_perc_bv,
         perc_imposto     = v_perc_imposto,
         tipo_fatur_bv    = v_tipo_fatur_bv,
         valor_fornecedor = v_valor_fornecedor_new
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  v_valor_bv  := round(v_valor_fornecedor_new * v_perc_bv / 100, 2);
  v_valor_tip := round((v_valor_aprovado_ori - v_valor_fornecedor_new) * (1 - v_perc_imposto / 100),
                       2);
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_delimitador        := '|';
  v_vetor_item_nota_id := p_vetor_item_nota_id;
  v_vetor_valor_fornec := p_vetor_valor_fornec;
  v_vetor_valor_bv     := p_vetor_valor_bv;
  v_vetor_valor_tip    := p_vetor_valor_tip;
  --
  WHILE nvl(length(rtrim(v_vetor_item_nota_id)), 0) > 0
  LOOP
   v_item_nota_id      := to_number(prox_valor_retornar(v_vetor_item_nota_id, v_delimitador));
   v_valor_fornec_char := prox_valor_retornar(v_vetor_valor_fornec, v_delimitador);
   v_valor_bv_char     := prox_valor_retornar(v_vetor_valor_bv, v_delimitador);
   v_valor_tip_char    := prox_valor_retornar(v_vetor_valor_tip, v_delimitador);
   --
   SELECT nota_fiscal_id,
          carta_acordo_id,
          valor_aprovado,
          nota_fiscal_pkg.bv_nf_saida_retornar(nota_fiscal_id)
     INTO v_nota_fiscal_id,
          v_carta_acordo_id,
          v_valor_aprov_it,
          v_nota_fiscal_sai_id
     FROM item_nota
    WHERE item_nota_id = v_item_nota_id;
   --
   IF v_nota_fiscal_sai_id IS NULL
   THEN
    -- essa NF nao tem BV já faturado. Pode alterar o rateio.
    --
    IF v_carta_acordo_id <> p_carta_acordo_id
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem itens no vetor que não estão associados a essa carta acordo.';
     RAISE v_exception;
    END IF;
    --
    IF rtrim(v_valor_fornec_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Os valores de fornecedor a serem rateados entre os ' ||
                   'itens devem ser informados.';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_fornec_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor de fornecedor informado para o item inválido (' || v_valor_fornec_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF rtrim(v_valor_bv_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Os valores de BV a serem rateados entre os ' || 'itens devem ser informados.';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_bv_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor de BV informado para o item inválido (' || v_valor_bv_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF rtrim(v_valor_tip_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Os valores de TIP a serem rateados entre os ' || 'itens devem ser informados.';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_tip_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor de TIP informado para o item inválido (' || v_valor_tip_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_valor_fornec_it := nvl(moeda_converter(v_valor_fornec_char), 0);
    v_valor_bv_it     := nvl(moeda_converter(v_valor_bv_char), 0);
    v_valor_tip_it    := nvl(moeda_converter(v_valor_tip_char), 0);
    --
    /*
    v_valor_bv_it := ROUND(v_valor_fornec_it * v_perc_bv /100,2);
    v_valor_tip_it := ROUND((v_valor_aprov_it - v_valor_fornec_it) *
                                   (1 - v_perc_imposto/100), 2);*/
    --
    UPDATE item_nota
       SET valor_fornecedor = v_valor_fornec_it,
           valor_bv         = v_valor_bv_it,
           valor_tip        = v_valor_tip_it
     WHERE item_nota_id = v_item_nota_id;
   
   END IF; -- fim do v_nota_fiscal_sai_id IS NULL
  END LOOP;
  --
  ------------------------------------------------------------
  -- redistribuicao de item_carta baseado no que o usuario
  -- informou para valor de fornecedor.
  ------------------------------------------------------------
  IF v_tem_nf = 'S'
  THEN
   UPDATE item_carta ic
      SET valor_fornecedor =
          (SELECT nvl(SUM(valor_fornecedor), 0)
             FROM item_nota it
            WHERE it.carta_acordo_id = ic.carta_acordo_id
              AND it.item_id = ic.item_id)
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  ELSE
   IF v_valor_fornecedor_old <> 0
   THEN
    UPDATE item_carta ic
       SET valor_fornecedor = round(valor_fornecedor * v_valor_fornecedor_new /
                                    v_valor_fornecedor_old,
                                    2)
     WHERE carta_acordo_id = p_carta_acordo_id;
   
   ELSE
    UPDATE item_carta ic
       SET valor_fornecedor = round(valor_aprovado * v_valor_fornecedor_new / v_valor_aprovado_ori,
                                    2)
     WHERE carta_acordo_id = p_carta_acordo_id;
   
   END IF;
  END IF;
  --
  -- verifica se os novos valores de fornecedor informados batem com
  -- o valor de fornecedor total da carta acordo.
  SELECT nvl(SUM(valor_fornecedor), 0)
    INTO v_valor_fornecedor_aux
    FROM item_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  /*IF v_valor_fornecedor_aux <> v_valor_fornecedor_new
  THEN
   -- houve erro na informacao do rateio ou podem existir "item_id" repetidos
   -- na tabela item_carta.
   p_erro_cod := '90000';
   p_erro_msg := 'A soma dos valores de fornecedor distribuídos entre os itens (' ||
                 moeda_mostrar(v_valor_fornecedor_aux, 'S') ||
                 ') não bate com o valor de fornecedor total informado na carta acordo (' ||
                 moeda_mostrar(v_valor_fornecedor_new, 'S') || ').';
  
   RAISE v_exception;
  END IF;*/
  --
  /*IF v_tem_nf = 'S'
  THEN
   -- verifica se os novos valores de bv e tip informados batem com
   -- os valores da carta acordo.
   SELECT nvl(SUM(valor_bv), 0) + nvl(SUM(valor_tip), 0)
     INTO v_valor_bv_tip_new
     FROM item_nota
    WHERE carta_acordo_id = p_carta_acordo_id;
   --
   \*IF v_valor_bv_tip_new <> v_valor_bv + v_valor_tip
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores de BV/TIP distribuídos entre os itens (' ||
                  moeda_mostrar(v_valor_bv_tip_new, 'S') || ') não bate ' ||
                  'com o valor BV/TIP total informado na carta acordo (' ||
                  moeda_mostrar(v_valor_bv + v_valor_tip, 'S') || ').';
   
    RAISE v_exception;
   END IF;*\
  
  END IF;*/
  --
  ------------------------------------------------------------
  -- refaturamento dos BVs associados a carta acordo
  ------------------------------------------------------------
  FOR r_fat IN c_fat
  LOOP
   --ALCBO_060825 
   SELECT nvl(SUM(valor_bv), 0) + nvl(SUM(valor_tip), 0)
     INTO v_valor_bv_tip_new
     FROM item_nota
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = r_fat.item_id;
   --ALCBO_120525 - Atualização de valor fatura
   UPDATE item_fatur
      SET valor_fatura = v_valor_bv_tip_new
    WHERE faturamento_id = r_fat.faturamento_id
      AND nota_fiscal_id = r_fat.nota_fiscal_id
      AND item_id = r_fat.item_id; --ALCBO_060825 distincao por item
   -- cancela faturamentos de BVs (ainda nao faturados) associados a carta acordo
   faturamento_pkg.excluir(p_usuario_sessao_id,
                           p_empresa_id,
                           'N',
                           r_fat.faturamento_id,
                           p_erro_cod,
                           p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  FOR r_nf IN c_nf
  LOOP
   UPDATE nota_fiscal
      SET tipo_fatur_bv = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id)
    WHERE nota_fiscal_id = r_nf.nota_fiscal_id;
   --
   -- gera o faturamento de BVs das NFs associadas a carta acordo, mas nao comanda
   faturamento_pkg.bv_gerar(p_usuario_sessao_id,
                            p_empresa_id,
                            r_nf.nota_fiscal_id,
                            'N',
                            v_faturamento_id,
                            p_erro_cod,
                            p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CARTA_ACORDO_ATUALIZAR',
                           p_empresa_id,
                           p_carta_acordo_id,
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
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ori, 'S') || ' - Antes (Tipo Fatur: ' ||
                      v_tipo_fatur_bv_old || '; Custo Forn: ' ||
                      moeda_mostrar(v_valor_fornecedor_old, 'S') || '; Perc BV: ' ||
                      numero_mostrar(v_perc_bv_old, 5, 'N') || '; Perc Imposto: ' ||
                      taxa_mostrar(v_perc_imposto_old) || '; BV+TIP: ' ||
                      moeda_mostrar(v_valor_bv_tip_old, 'S') || ')' || ' - Depois (Tipo Fatur: ' ||
                      v_tipo_fatur_bv || '; Custo Forn: ' ||
                      moeda_mostrar(v_valor_fornecedor_new, 'S') || '; Perc BV: ' ||
                      numero_mostrar(v_perc_bv, 5, 'N') || '; Perc Imposto: ' ||
                      taxa_mostrar(v_perc_imposto) || '; BV+TIP: ' ||
                      moeda_mostrar(v_valor_bv_tip_new, 'S') || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR_ESP1',
                   v_identif_objeto,
                   p_carta_acordo_id,
                   v_compl_histor,
                   p_justificativa,
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
  p_historico_id := v_historico_id;
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
 END; -- emitida_atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/04/2007
  -- DESCRICAO: Exclusão de CARTA_ACORDO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta multi-item.
  -- Silvia            02/04/2008  Consistencia de sobra.
  -- Silvia            30/04/2008  Consistencia de abatimento.
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            05/06/2009  Tratamento para arquivo duplo associado a uma CA.
  -- Silvia            02/08/2011  Cursor para excluir todos os arquivos da CA.
  -- Silvia            28/09/2020  Exclusao de sobra associada.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ca   carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv             carta_acordo.perc_bv%TYPE;
  v_perc_imposto        carta_acordo.perc_imposto%TYPE;
  v_tipo_fatur_bv       carta_acordo.tipo_fatur_bv%TYPE;
  v_fornecedor_id       carta_acordo.fornecedor_id%TYPE;
  v_valor_credito_usado carta_acordo.valor_credito_usado%TYPE;
  v_fornecedor          pessoa.apelido%TYPE;
  v_valor_bv_tip        NUMBER;
  v_operador            lancamento.operador%TYPE;
  v_descricao           lancamento.descricao%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_xml_atual           CLOB;
  --
  CURSOR c_it IS
   SELECT ic.item_carta_id,
          ic.item_id,
          it.job_id
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id;
  --
  CURSOR c_aq IS
   SELECT ac.arquivo_id,
          ta.codigo AS cod_tipo_arquivo
     FROM arquivo_carta ac,
          arquivo       ar,
          tipo_arquivo  ta
    WHERE ac.carta_acordo_id = p_carta_acordo_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.tipo_arquivo_id = ta.tipo_arquivo_id;
  --
  CURSOR c_is IS
   SELECT io.item_sobra_id,
          io.item_id
     FROM sobra      so,
          item_sobra io
    WHERE so.carta_acordo_id = p_carta_acordo_id
      AND so.sobra_id = io.sobra_id;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo ca
   WHERE ca.carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         pe.apelido,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0),
         ca.fornecedor_id,
         ca.tipo_fatur_bv,
         nvl(ca.valor_credito_usado, 0)
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_fornecedor,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv,
         v_perc_imposto,
         v_fornecedor_id,
         v_tipo_fatur_bv,
         v_valor_credito_usado
    FROM carta_acordo ca,
         job          jo,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+)
     AND ca.fornecedor_id = pe.pessoa_id(+);
  --
  IF v_status_ca = 'EMITIDA'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_X',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_E',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota
   WHERE carta_acordo_id = p_carta_acordo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo já tem notas fiscais associadas.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur
   WHERE carta_acordo_id = p_carta_acordo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo já tem faturamento associado.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM sobra
     WHERE carta_acordo_id = p_carta_acordo_id
       AND ROWNUM = 1;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa carta acordo já tem sobras associadas.';
       RAISE v_exception;
    END IF;
  */
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM abatimento
   WHERE carta_acordo_id = p_carta_acordo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo já tem abatimentos associados.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  v_valor_bv_tip := round(v_valor_fornecedor_ca * v_perc_bv / 100, 2) +
                    round((v_valor_aprovado_ca - v_valor_fornecedor_ca) *
                          (1 - v_perc_imposto / 100),
                          2);
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('CARTA_ACORDO_EXCLUIR',
                           p_empresa_id,
                           p_carta_acordo_id,
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
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (excusao das sobras)
  ------------------------------------------------------------
  FOR r_is IN c_is
  LOOP
   DELETE FROM item_sobra
    WHERE item_sobra_id = r_is.item_sobra_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_is.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM sobra so
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_valor_credito_usado > 0
  THEN
   -- estorno do uso do credito pela agencia junto ao fornecedor (movimento de entrada)
   v_descricao := 'Estorno do uso do crédito pela ' || v_lbl_agencia_singular || ': ' ||
                  v_num_carta_formatado;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     v_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_credito_usado,
     'E',
     v_operador,
     NULL);
  
  END IF;
  --
  FOR r_aq IN c_aq
  LOOP
   arquivo_pkg.excluir(p_usuario_sessao_id, r_aq.arquivo_id, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM email_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
 
  DELETE FROM parcela_carta
   WHERE carta_acordo_id = p_carta_acordo_id;
 
  DELETE FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  FOR r_it IN c_it
  LOOP
   IF v_job_id IS NULL
   THEN
    -- carta acordo multi job. Pega o job do item
    job_pkg.status_tratar(p_usuario_sessao_id,
                          p_empresa_id,
                          r_it.job_id,
                          'ALL',
                          p_erro_cod,
                          p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   DELETE FROM item_carta
    WHERE item_carta_id = r_it.item_carta_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_job_id IS NOT NULL
  THEN
   -- carta acordo mono job
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 06/02/2009
  -- DESCRICAO: Aprovacao de CARTA_ACORDO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/05/2009  Consiste bloqueio da negociacao
  -- Silvia            09/01/2015  Trata sequencia de aprovacoes.
  -- Silvia            24/02/2015  Guarda usuarios da ultima aprovacao
  -- Silvia            20/04/2015  Instanciacao do fluxo de aprovacao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_flag_bloq_negoc     job.flag_bloq_negoc%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ca   carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv             carta_acordo.perc_bv%TYPE;
  v_flag_com_aprov      carta_acordo.flag_com_aprov%TYPE;
  v_flag_aprov_seq      carta_acordo.flag_aprov_seq%TYPE;
  v_fornecedor          pessoa.apelido%TYPE;
  v_comentario_id       comentario.comentario_id%TYPE;
  v_faixa_aprov_id      faixa_aprov.faixa_aprov_id%TYPE;
  v_seq_aprov           carta_fluxo_aprov.seq_aprov%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_qtd_aprov_max       faixa_aprov_papel.seq_aprov%TYPE;
  v_qtd_aprov_atu       faixa_aprov_papel.seq_aprov%TYPE;
  v_papel_id            papel.papel_id%TYPE;
  v_qtd_fluxo           INTEGER;
  v_seq_aprov_maior     carta_fluxo_aprov.seq_aprov%TYPE;
  v_papel_aux_id        papel.papel_id%TYPE;
  v_tipo_aprov          VARCHAR2(50);
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         jo.flag_bloq_negoc,
         pe.apelido,
         ca.num_carta_formatado,
         ca.valor_aprovado,
         ca.valor_fornecedor,
         ca.perc_bv,
         ca.flag_com_aprov,
         ca.flag_aprov_seq
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_flag_bloq_negoc,
         v_fornecedor,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv,
         v_flag_com_aprov,
         v_flag_aprov_seq
    FROM carta_acordo ca,
         job          jo,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+)
     AND ca.fornecedor_id = pe.pessoa_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_AP',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca <> 'EMAPRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não se encontra em aprovação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias de parametros
  ------------------------------------------------------------
  IF length(TRIM(p_comentario)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de aprovacao
  ------------------------------------------------------------
  v_faixa_aprov_id := 0;
  v_qtd_fluxo      := 0;
  --
  IF v_flag_com_aprov = 'S'
  THEN
   -- carta criada com aprovacao de AO.
   -- verifica se fluxo esta instanciado
   SELECT COUNT(*)
     INTO v_qtd_fluxo
     FROM carta_fluxo_aprov
    WHERE carta_acordo_id = p_carta_acordo_id;
   --
   IF v_qtd_fluxo = 0
   THEN
    -- fluxo nao instanciado.
    -- precisa verificar faixa.
    v_faixa_aprov_id := carta_acordo_pkg.faixa_aprov_id_retornar(p_usuario_sessao_id,
                                                                 p_empresa_id,
                                                                 p_carta_acordo_id);
    --
    -- retorno 0 indica que a empresa nao usa faixa ou o usuario nao necessita de verificacao (admin)
    -- retorno -1 indica que o usuario nao pode aprovar esse valor
    IF v_faixa_aprov_id = -1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário não pode aprovar essa faixa de valor.';
     RAISE v_exception;
    END IF;
    --
    IF v_faixa_aprov_id > 0
    THEN
     -- precisa instanciar o fluxo
     SELECT flag_sequencial
       INTO v_flag_aprov_seq
       FROM faixa_aprov
      WHERE faixa_aprov_id = v_faixa_aprov_id;
     --
     INSERT INTO carta_fluxo_aprov
      (carta_acordo_id,
       papel_id,
       seq_aprov)
      SELECT p_carta_acordo_id,
             papel_id,
             seq_aprov
        FROM faixa_aprov_papel
       WHERE faixa_aprov_id = v_faixa_aprov_id;
     --
     UPDATE carta_acordo
        SET flag_aprov_seq = v_flag_aprov_seq,
            faixa_aprov_id = v_faixa_aprov_id
      WHERE carta_acordo_id = p_carta_acordo_id;
    
    END IF;
   
   END IF; -- fim do IF v_qtd_fluxo = 0
   --
   -- testa novamente para atualizar a qtd
   SELECT COUNT(*)
     INTO v_qtd_fluxo
     FROM carta_fluxo_aprov
    WHERE carta_acordo_id = p_carta_acordo_id;
   --
   IF v_qtd_fluxo > 0
   THEN
    -- existe um fluxo em andamento.
    IF v_flag_aprov_seq = 'S'
    THEN
     -- aprovacao deve obedecer a sequencia.
     SELECT nvl(MAX(seq_aprov), 0)
       INTO v_seq_aprov_maior
       FROM carta_fluxo_aprov
      WHERE carta_acordo_id = p_carta_acordo_id
        AND data_aprov IS NOT NULL;
     --
     -- pega a proxima sequencia com aprovacao pendente
     SELECT nvl(MIN(seq_aprov), 0)
       INTO v_seq_aprov
       FROM carta_fluxo_aprov
      WHERE carta_acordo_id = p_carta_acordo_id
        AND data_aprov IS NULL
        AND seq_aprov > v_seq_aprov_maior;
     --
     -- Verifica o papel do usuario que pode aprovar nessa sequencia.
     SELECT MAX(up.papel_id)
       INTO v_papel_id
       FROM usuario_papel up
      WHERE up.usuario_id = p_usuario_sessao_id
        AND carta_acordo_pkg.papel_priv_verificar(up.usuario_id,
                                                  'CARTA_ACORDO_AP',
                                                  up.papel_id,
                                                  p_carta_acordo_id) = 1
        AND EXISTS (SELECT 1
               FROM carta_fluxo_aprov cf
              WHERE cf.carta_acordo_id = p_carta_acordo_id
                AND cf.papel_id = up.papel_id
                AND cf.seq_aprov = v_seq_aprov
                AND cf.data_aprov IS NULL);
     --
     IF v_papel_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Usuário não tem papel de aprovador para essa sequência ' ||
                    to_char(v_seq_aprov) || '.';
      RAISE v_exception;
     END IF;
    
    ELSE
     -- aprovacao nao precisa obedecer a sequencia. Verifica o papel do
     -- usuario que pode aprovar em qualquer sequencia ainda nao aprovada.
     SELECT MAX(up.papel_id)
       INTO v_papel_id
       FROM usuario_papel     up,
            carta_fluxo_aprov cf
      WHERE up.usuario_id = p_usuario_sessao_id
        AND carta_acordo_pkg.papel_priv_verificar(up.usuario_id,
                                                  'CARTA_ACORDO_AP',
                                                  up.papel_id,
                                                  p_carta_acordo_id) = 1
        AND cf.carta_acordo_id = p_carta_acordo_id
        AND cf.papel_id = up.papel_id
        AND cf.data_aprov IS NULL
        AND NOT EXISTS (SELECT 1
               FROM carta_fluxo_aprov c2
              WHERE c2.carta_acordo_id = cf.carta_acordo_id
                AND cf.seq_aprov = cf.seq_aprov
                AND cf.data_aprov IS NOT NULL);
     --
     IF v_papel_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Usuário não tem papel de aprovador para esse fluxo.';
      RAISE v_exception;
     END IF;
     --
     v_seq_aprov := 0;
    END IF;
   ELSE
    -- fluxo de aprovacao nao encontrado.
    -- pega o papel_id do aprovador para gravar no log
    SELECT MAX(up.papel_id)
      INTO v_papel_id
      FROM usuario_papel up,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo IN ('CARTA_ACORDO_AP', 'CARTA_ACORDO_SAO');
    --
    IF v_papel_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário não tem papel de aprovador.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO carta_fluxo_aprov
     (carta_acordo_id,
      papel_id,
      seq_aprov)
    VALUES
     (p_carta_acordo_id,
      v_papel_id,
      1);
    --
    UPDATE carta_acordo
       SET flag_aprov_seq = 'N'
     WHERE carta_acordo_id = p_carta_acordo_id;
    --
    v_qtd_fluxo := 1;
    v_seq_aprov := 1;
   END IF; -- fim do IF v_qtd_fluxo > 0
  END IF; -- fim do IF v_flag_com_aprov = 'S
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_qtd_aprov_atu := 0;
  v_qtd_aprov_max := 0;
  v_tipo_aprov    := 'Aprovação parcial';
  --
  IF TRIM(p_comentario) IS NOT NULL
  THEN
   comentario_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            'CARTA_ACORDO',
                            p_carta_acordo_id,
                            'PRINCIPAL',
                            0,
                            'Comentários da Aprovação: ' || TRIM(p_comentario),
                            v_comentario_id,
                            p_erro_cod,
                            p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_com_aprov = 'S' AND v_qtd_fluxo > 0
  THEN
   -- carta criada com aprovacao de AO e fluxo.
   IF v_seq_aprov = 0
   THEN
    -- marca como aprovada todas as sequencias ainda nao aprovadas
    -- do papel encontrado
    UPDATE carta_fluxo_aprov cf
       SET usuario_aprov_id = p_usuario_sessao_id,
           data_aprov       = SYSDATE
     WHERE carta_acordo_id = p_carta_acordo_id
       AND papel_id = v_papel_id
       AND NOT EXISTS (SELECT 1
              FROM carta_fluxo_aprov c2
             WHERE c2.carta_acordo_id = cf.carta_acordo_id
               AND cf.seq_aprov = cf.seq_aprov
               AND cf.data_aprov IS NOT NULL);
   
   ELSE
    -- marca como aprovado o papel/sequencia encontrados e eventualmente
    -- as proximas sequencias (se forem do mesmo papel).
    v_papel_aux_id := v_papel_id;
    --
    WHILE v_seq_aprov <= v_qtd_fluxo AND v_papel_aux_id = v_papel_id
    LOOP
     UPDATE carta_fluxo_aprov
        SET usuario_aprov_id = p_usuario_sessao_id,
            data_aprov       = SYSDATE
      WHERE carta_acordo_id = p_carta_acordo_id
        AND papel_id = v_papel_id
        AND seq_aprov = v_seq_aprov;
     --
     v_seq_aprov := v_seq_aprov + 1;
     --
     SELECT nvl(MAX(papel_id), 0)
       INTO v_papel_aux_id
       FROM carta_fluxo_aprov
      WHERE carta_acordo_id = p_carta_acordo_id
        AND papel_id = v_papel_id
        AND seq_aprov = v_seq_aprov;
    
    END LOOP;
   
   END IF;
   --
   -- Verifica qtd de aprovacoes.
   SELECT COUNT(DISTINCT seq_aprov)
     INTO v_qtd_aprov_atu
     FROM carta_fluxo_aprov
    WHERE carta_acordo_id = p_carta_acordo_id
      AND data_aprov IS NOT NULL;
   --
   SELECT nvl(MAX(seq_aprov), 0)
     INTO v_qtd_aprov_max
     FROM carta_fluxo_aprov
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  IF v_flag_com_aprov = 'N' OR v_qtd_aprov_atu >= v_qtd_aprov_max
  THEN
   -- carta criada sem aprovacao de AO ou atingiu a qtd necessaria de
   -- aprovacoes. Pode mudar de status.
   UPDATE carta_acordo
      SET status         = 'EMEMIS',
          data_aprovacao = SYSDATE
    WHERE carta_acordo_id = p_carta_acordo_id;
   --
   v_tipo_aprov := 'Aprovação final';
   --
   IF v_job_id IS NOT NULL
   THEN
    job_pkg.status_tratar(p_usuario_sessao_id,
                          p_empresa_id,
                          v_job_id,
                          'ALL',
                          p_erro_cod,
                          p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := v_tipo_aprov;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'APROVAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
                   v_compl_histor,
                   TRIM(p_comentario),
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
 END; -- aprovar
 --
 --
 PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 06/02/2009
  -- DESCRICAO: Reprovacao de CARTA_ACORDO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/09/2015  Motivo da reprovacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ca   carta_acordo.valor_aprovado%TYPE;
  v_fornecedor          pessoa.apelido%TYPE;
  v_comentario_id       comentario.comentario_id%TYPE;
  v_motivo_reprov_desc  VARCHAR2(200);
  v_lbl_job             VARCHAR2(100);
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         pe.apelido,
         ca.num_carta_formatado,
         ca.valor_aprovado
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_fornecedor,
         v_num_carta_formatado,
         v_valor_aprovado_ca
    FROM carta_acordo ca,
         job          jo,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+)
     AND ca.fornecedor_id = pe.pessoa_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_AP',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca <> 'EMAPRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não se encontra em aprovação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_motivo_reprov) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_motivo_reprov_desc := util_pkg.desc_retornar('motivo_reprov_ca', p_motivo_reprov);
  --
  IF v_motivo_reprov_desc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Motivo inválido (' || p_motivo_reprov || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_comentario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do comentário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_comentario)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF TRIM(p_comentario) IS NOT NULL
  THEN
   comentario_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            'CARTA_ACORDO',
                            p_carta_acordo_id,
                            'PRINCIPAL',
                            0,
                            'Comentários da Reprovação: ' || TRIM(p_comentario),
                            v_comentario_id,
                            p_erro_cod,
                            p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  UPDATE carta_acordo
     SET status         = 'REPROV',
         data_aprovacao = NULL,
         faixa_aprov_id = NULL
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  DELETE FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_job_id IS NOT NULL
  THEN
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := TRIM(p_comentario);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'REPROVAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
                   v_compl_histor,
                   v_motivo_reprov_desc,
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
 END; -- reprovar
 --
 --
 PROCEDURE emitir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 23/04/2007
  -- DESCRICAO: Emissao de CARTA_ACORDO (marca a carta como emitida e grava o arquivo no
  --   banco).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta multi-item.
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            28/05/2009  Verificacao de arquivo gerado duas vezes (duplo clique).
  -- Silvia            29/05/2009  Consiste bloqueio da negociacao
  -- Silvia            20/06/2014  Novo tipo de BV: permutar
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_pessoa_id         IN arquivo_pessoa.pessoa_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_flag_bloq_negoc     job.flag_bloq_negoc%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_valor_aprovado_ca   carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca carta_acordo.valor_fornecedor%TYPE;
  v_perc_bv             carta_acordo.perc_bv%TYPE;
  v_perc_imposto        carta_acordo.perc_imposto%TYPE;
  v_tipo_fatur_bv       carta_acordo.tipo_fatur_bv%TYPE;
  v_valor_credito_usado carta_acordo.valor_credito_usado%TYPE;
  v_fornecedor_id       carta_acordo.fornecedor_id%TYPE;
  v_fornecedor          pessoa.apelido%TYPE;
  v_tipo_arquivo_id     tipo_arquivo.tipo_arquivo_id%TYPE;
  v_num_orcam           VARCHAR2(30);
  v_orcamento_id        orcamento.orcamento_id%TYPE;
  v_valor_bv_tip        NUMBER;
  v_operador            lancamento.operador%TYPE;
  v_descricao           lancamento.descricao%TYPE;
  v_nota_fiscal_id      nota_fiscal.nota_fiscal_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo ca
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         jo.flag_bloq_negoc,
         pe.apelido,
         ca.num_carta_formatado,
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0),
         ca.tipo_fatur_bv,
         nvl(ca.valor_credito_usado, 0),
         ca.fornecedor_id
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_flag_bloq_negoc,
         v_fornecedor,
         v_num_carta_formatado,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_perc_bv,
         v_perc_imposto,
         v_tipo_fatur_bv,
         v_valor_credito_usado,
         v_fornecedor_id
    FROM carta_acordo ca,
         job          jo,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+)
     AND ca.fornecedor_id = pe.pessoa_id(+);
  --
  -- verifica se existe orcamento associado a essa carta que nao se encontra
  -- no status aprovado.
  SELECT MIN(oc.orcamento_id)
    INTO v_orcamento_id
    FROM item_carta ic,
         item       it,
         orcamento  oc
   WHERE ic.carta_acordo_id = p_carta_acordo_id
     AND ic.item_id = it.item_id
     AND it.orcamento_id = oc.orcamento_id
     AND oc.status <> 'APROV';
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_EM',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   -- privilegio do grupo ORCEND
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_orcamento_id IS NOT NULL
  THEN
   SELECT orcamento_pkg.numero_formatar(v_orcamento_id)
     INTO v_num_orcam
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
   --
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos ' || v_num_orcam ||
                 ' não permite a emissão da carta acordo.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca <> 'EMEMIS'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não se encontra aguardando emissão.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_bloq_negoc = 'S' AND ((v_valor_aprovado_ca > v_valor_fornecedor_ca) OR
     (v_perc_bv <> 0 AND v_valor_fornecedor_ca <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse ' || v_lbl_job ||
                 ', valores de negociação não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_carta ac,
         arquivo       ar,
         tipo_arquivo  ti
   WHERE ac.carta_acordo_id = p_carta_acordo_id
     AND ac.arquivo_id = ar.arquivo_id
     AND ar.tipo_arquivo_id = ti.tipo_arquivo_id
     AND ti.codigo = 'CARTA_ACORDO';
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo já tem um arquivo PDF gerado.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  v_valor_bv_tip := round(v_valor_fornecedor_ca * v_perc_bv / 100, 2) +
                    round((v_valor_aprovado_ca - v_valor_fornecedor_ca) *
                          (1 - v_perc_imposto / 100),
                          2);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'CARTA_ACORDO';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_carta_acordo_id,
                        v_tipo_arquivo_id,
                        p_nome_original,
                        p_nome_fisico,
                        p_descricao,
                        p_mime_type,
                        p_tamanho,
                        NULL,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE carta_acordo
     SET status       = 'EMITIDA',
         data_emissao = SYSDATE
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_job_id IS NOT NULL
  THEN
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_valor_credito_usado > 0 OR v_tipo_fatur_bv = 'PER'
  THEN
   nota_fiscal_pkg.auto_adicionar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_carta_acordo_id,
                                  v_nota_fiscal_id,
                                  p_erro_cod,
                                  p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  carta_acordo_pkg.xml_gerar(p_carta_acordo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Fornecedor: ' || v_fornecedor || ' - Valor: ' ||
                      moeda_mostrar(v_valor_aprovado_ca, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'EMITIR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  -- *** ATENCAO *** : ficou depois do evento para pegar o usuario emissor no log
  it_controle_pkg.integrar('CARTA_ACORDO_ADICIONAR',
                           p_empresa_id,
                           p_carta_acordo_id,
                           NULL,
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
 END emitir;
 --
 --
 PROCEDURE email_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 08/05/2008
  -- DESCRICAO: registra dados do email enviado ao forcecedor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            02/09/2015  Novos parametros para atualizar email do fornecedor.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN email_carta.carta_acordo_id%TYPE,
  p_fornecedor_id     IN carta_acordo.fornecedor_id%TYPE,
  p_enviar_para       IN email_carta.enviar_para%TYPE,
  p_enviado_por       IN email_carta.enviado_por%TYPE,
  p_responder_para    IN email_carta.responder_para%TYPE,
  p_assunto           IN email_carta.assunto%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_email_carta_id      email_carta.email_carta_id%TYPE;
  v_enviar_para         email_carta.enviar_para%TYPE;
  v_flag_atu_email      CHAR(1);
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_EM',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca <> 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo ainda não foi emitida.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A escolha do email é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  v_flag_atu_email := 'N';
  --
  -- recupera o email atual do fornecedor
  SELECT TRIM(email)
    INTO v_enviar_para
    FROM pessoa
   WHERE pessoa_id = p_fornecedor_id;
  --
  IF v_enviar_para IS NULL AND TRIM(p_enviar_para) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O email do fornecedor não foi especificado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_enviar_para) IS NOT NULL
  THEN
   -- outro email foi informado
   IF email_validar(TRIM(p_enviar_para)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Email inválido (' || TRIM(p_enviar_para) || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_enviar_para, '-') <> TRIM(p_enviar_para)
   THEN
    v_flag_atu_email := 'S';
   END IF;
   --
   v_enviar_para := TRIM(p_enviar_para);
  END IF;
  --
  IF p_enviado_por IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O email do remetente não foi especificado.';
   RAISE v_exception;
  END IF;
  --
  IF p_responder_para IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O email de resposta não foi especificado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_email_carta.nextval
    INTO v_email_carta_id
    FROM dual;
  --
  INSERT INTO email_carta
   (email_carta_id,
    carta_acordo_id,
    usuario_resp_id,
    data_email,
    enviar_para,
    assunto,
    enviado_por,
    responder_para)
  VALUES
   (v_email_carta_id,
    p_carta_acordo_id,
    p_usuario_sessao_id,
    SYSDATE,
    v_enviar_para,
    p_assunto,
    TRIM(p_enviado_por),
    TRIM(p_responder_para));
  --
  IF v_flag_atu_email = 'S'
  THEN
   UPDATE pessoa
      SET email = v_enviar_para
    WHERE pessoa_id = p_fornecedor_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Registro de email da carta acordo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END email_registrar;
 --
 --
 PROCEDURE enviada_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 03/03/2008
  -- DESCRICAO: marca a carta acordo como enviada
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_envio        IN carta_acordo.tipo_envio%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_EM',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_ca <> 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo ainda não foi emitida.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_envio IS NULL OR p_tipo_envio NOT IN ('EMAIL', 'OUTRO')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de envio inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET tipo_envio = p_tipo_envio,
         data_envio = SYSDATE
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Envio da carta acordo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END; -- enviada_marcar
 --
 --
 PROCEDURE enviada_desmarcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 03/03/2008
  -- DESCRICAO: desmarca a carta acordo como enviada
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_num_job,
         v_status_job,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_EM',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_SAO',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE carta_acordo
     SET tipo_envio = NULL,
         data_envio = NULL
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Envio da carta acordo desfeito';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END; -- enviada_desmarcar
 --
 --
 PROCEDURE parcela_simular
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/12/2013
  -- DESCRICAO: rotina que simula valores e datas de vencimento da carta acordo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_valor_a_parcelar  IN VARCHAR2,
  p_vetor_num_parcela OUT VARCHAR2,
  p_vetor_data        OUT VARCHAR2,
  p_vetor_dia_semana  OUT VARCHAR2,
  p_vetor_perc        OUT VARCHAR2,
  p_vetor_valor       OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
 
  v_qt                     INTEGER;
  v_vetor_num_parcela      LONG;
  v_vetor_data             LONG;
  v_vetor_dia_semana       LONG;
  v_vetor_perc             LONG;
  v_vetor_valor            LONG;
  v_data_base              DATE;
  v_data_parcela           DATE;
  v_data_parcela_pri       DATE;
  v_num_dias_fatur_interno INTEGER;
  v_num_dias_fatur_cli     INTEGER;
  v_valor                  NUMBER;
  v_num_parcela            condicao_pagto_det.num_parcela%TYPE;
  v_valor_perc             condicao_pagto_det.valor_perc%TYPE;
  v_num_dias               condicao_pagto_det.num_dias%TYPE;
  v_dia_semana             VARCHAR2(10);
  v_valor_total            item.valor_aprovado%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_qt_parc                INTEGER;
  v_valor_acum             NUMBER;
  --
  CURSOR c_cond IS
   SELECT num_parcela,
          valor_perc,
          num_dias
     FROM condicao_pagto_det
    WHERE condicao_pagto_id = p_condicao_pagto_id
    ORDER BY num_parcela;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_condicao_pagto_id, 0) = 0
  THEN
   RAISE v_saida;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa condição de pagamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt_parc
    FROM condicao_pagto_det
   WHERE condicao_pagto_id = p_condicao_pagto_id;
  --
  IF moeda_validar(p_valor_a_parcelar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor a parcelar inválido ( ' || p_valor_a_parcelar || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_total := nvl(moeda_converter(p_valor_a_parcelar), 0);
  --
  IF v_valor_total < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor a parcelar inválido ( ' || p_valor_a_parcelar || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur_interno := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_DIAS_FATUR_INTERNO')),
                                  0);
 
  v_num_dias_fatur_cli := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_FATUR_CLI')),
                              0);
  --
  ------------------------------------------------------------
  -- simulacao do parcelamento
  ------------------------------------------------------------
  v_data_base  := trunc(SYSDATE);
  v_valor_acum := 0;
  --
  FOR r_cond IN c_cond
  LOOP
   v_num_parcela := r_cond.num_parcela;
   v_valor_perc  := r_cond.valor_perc;
   v_num_dias    := r_cond.num_dias;
   --
   IF v_valor_perc <> 0
   THEN
    IF v_num_parcela = 1
    THEN
     -- a data primeira parcela é a maior data dos dois calculos
     -- a seguir:
     v_data_parcela := v_data_base + v_num_dias_fatur_interno;
     --
     v_data_parcela := v_data_parcela + v_num_dias_fatur_cli;
     --
     IF v_data_base + v_num_dias > v_data_parcela
     THEN
      v_data_parcela := v_data_base + v_num_dias;
     END IF;
     --
     v_data_parcela_pri := v_data_parcela;
    ELSE
     -- as demais parcelas seguem os dias da condicao de pagto
     -- selecionada.
     v_data_parcela := v_data_parcela_pri + v_num_dias;
    END IF;
    --
    -- aplica a regra da condicao de pagamento
    v_data_parcela := condicao_pagto_pkg.data_retornar(p_usuario_sessao_id,
                                                       p_condicao_pagto_id,
                                                       v_data_parcela);
    --
    IF v_data_parcela IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na aplicação da condição de pagamento.';
     RAISE v_exception;
    END IF;
    --
    v_valor      := round(v_valor_total * v_valor_perc / 100, 2);
    v_valor_acum := v_valor_acum + v_valor;
    v_dia_semana := dia_semana_mostrar(v_data_parcela);
    --
    IF v_num_parcela = v_qt_parc
    THEN
     -- na ultima parcela, ajusta eventuais diferencas de
     -- arredondamento.
     IF v_valor_acum <> v_valor_total
     THEN
      v_valor := v_valor + v_valor_total - v_valor_acum;
     END IF;
    END IF;
    --
    v_vetor_num_parcela := v_vetor_num_parcela || '|' || to_char(v_num_parcela);
    v_vetor_data        := v_vetor_data || '|' || data_mostrar(v_data_parcela);
    v_vetor_dia_semana  := v_vetor_dia_semana || '|' || v_dia_semana;
    v_vetor_perc        := v_vetor_perc || '|' || numero_mostrar(v_valor_perc, 4, 'N');
    v_vetor_valor       := v_vetor_valor || '|' || moeda_mostrar(v_valor, 'N');
   END IF;
   --
  END LOOP;
  --
  -- retira o primeiro pipe
  IF substr(v_vetor_num_parcela, 1, 1) = '|'
  THEN
   v_vetor_num_parcela := substr(v_vetor_num_parcela, 2);
   v_vetor_data        := substr(v_vetor_data, 2);
   v_vetor_dia_semana  := substr(v_vetor_dia_semana, 2);
   v_vetor_perc        := substr(v_vetor_perc, 2);
   v_vetor_valor       := substr(v_vetor_valor, 2);
  END IF;
  --
  p_vetor_num_parcela := v_vetor_num_parcela;
  p_vetor_data        := v_vetor_data;
  p_vetor_dia_semana  := v_vetor_dia_semana;
  p_vetor_perc        := v_vetor_perc;
  p_vetor_valor       := v_vetor_valor;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
 END parcela_simular;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 08/09/2015
  -- DESCRICAO: Adicionar arquivo na Carta Acordo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/07/2016  Novo tipo de arquivo CARTA_ACORDO_ORCAM.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_tipo_arq_ca       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_tipo_arquivo_id     tipo_arquivo.tipo_arquivo_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo ca
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_numero_job,
         v_status_job,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF p_tipo_arq_ca = 'CARTA_ACORDO_ACEI'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_SAO',
                                  NULL,
                                  p_carta_acordo_id,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_A',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_ca = 'CARTA_ACORDO_ACEI' AND v_status_ca <> 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da carta acordo não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_ca = 'CARTA_ACORDO_ORCAM' AND v_status_ca = 'EMITIDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da carta acordo não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = p_tipo_arq_ca;
  --
  IF v_tipo_arquivo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de arquivo não existe (' || p_tipo_arq_ca || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_carta_acordo_id,
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
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_ca = 'CARTA_ACORDO_ACEI'
  THEN
   -- marca o aceite da carta acordo
   UPDATE carta_acordo
      SET status_aceite   = 'ACEI_CDOC',
          data_aceite     = SYSDATE,
          usuario_acei_id = p_usuario_sessao_id
    WHERE carta_acordo_id = p_carta_acordo_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Anexação de arquivo (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 08/09/2015
  -- DESCRICAO: Excluir arquivo da Carta Acordo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_nome_original       arquivo.nome_original%TYPE;
  v_cod_tipo_arquivo    tipo_arquivo.codigo%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_carta
   WHERE arquivo_id = p_arquivo_id
     AND carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ar.nome_original,
         ta.codigo
    INTO v_nome_original,
         v_cod_tipo_arquivo
    FROM arquivo_carta ac,
         arquivo       ar,
         tipo_arquivo  ta
   WHERE ac.arquivo_id = p_arquivo_id
     AND ac.carta_acordo_id = p_carta_acordo_id
     AND ac.arquivo_id = ar.arquivo_id
     AND ar.tipo_arquivo_id = ta.tipo_arquivo_id;
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_numero_job,
         v_status_job,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF v_cod_tipo_arquivo = 'CARTA_ACORDO_ACEI'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_C',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'CARTA_ACORDO_SAO',
                                  NULL,
                                  p_carta_acordo_id,
                                  p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'CARTA_ACORDO_A',
                                 NULL,
                                 p_carta_acordo_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_cod_tipo_arquivo = 'CARTA_ACORDO_ACEI'
  THEN
   -- verifica se sobraram mais arquivos de aceitacao
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_carta ac,
          arquivo       ar,
          tipo_arquivo  ta
    WHERE ac.carta_acordo_id = p_carta_acordo_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.tipo_arquivo_id = ta.tipo_arquivo_id
      AND ta.codigo = v_cod_tipo_arquivo;
   --
   IF v_qt = 0
   THEN
    -- desmarca o aceite
    UPDATE carta_acordo
       SET status_aceite   = 'PEND',
           data_aceite     = NULL,
           usuario_acei_id = NULL
     WHERE carta_acordo_id = p_carta_acordo_id;
   
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Exclusão de arquivo (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 PROCEDURE aceite_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 09/09/2015
  -- DESCRICAO: Registra o aceite do fornecedor, sem anexação de documentos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_status_aceite       carta_acordo.status_aceite%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.status_aceite,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_numero_job,
         v_status_job,
         v_status_aceite,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_A',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_aceite NOT IN ('NA', 'PEND')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do aceite não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- desmarca o aceite
  UPDATE carta_acordo
     SET status_aceite   = 'ACEI_SDOC',
         data_aceite     = SYSDATE,
         usuario_acei_id = p_usuario_sessao_id
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Registro do aceite do fornecedor';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END aceite_registrar;
 --
 --
 PROCEDURE aceite_desfazer
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 09/09/2015
  -- DESCRICAO: Apaga as informacoes de aceite de fornecedor, voltando o status para
  --  aceitacao pendente.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_status_ca           carta_acordo.status%TYPE;
  v_status_aceite       carta_acordo.status_aceite%TYPE;
  v_num_carta_formatado carta_acordo.num_carta_formatado%TYPE;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT ca.job_id,
         ca.status,
         jo.numero,
         jo.status,
         ca.status_aceite,
         ca.num_carta_formatado
    INTO v_job_id,
         v_status_ca,
         v_numero_job,
         v_status_job,
         v_status_aceite,
         v_num_carta_formatado
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARTA_ACORDO_A',
                                NULL,
                                p_carta_acordo_id,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_aceite NOT IN ('ACEI_CDOC', 'ACEI_SDOC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do aceite não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- desmarca o aceite
  UPDATE carta_acordo
     SET status_aceite   = 'PEND',
         data_aceite     = NULL,
         usuario_acei_id = NULL
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_carta_formatado;
  v_compl_histor   := 'Estorno do aceite do fornecedor';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARTA_ACORDO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_carta_acordo_id,
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
 END aceite_desfazer;
 --
 --
 PROCEDURE id_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 17/10/2008
  -- DESCRICAO: retorna o id da carta acordo de acordo com o numero do job e da carta.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_num_job          IN VARCHAR2,
  p_num_carta_acordo IN VARCHAR2,
  p_carta_acordo_id  OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_carta_acordo_id carta_acordo.carta_acordo_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  --
 BEGIN
  v_qt              := 0;
  p_carta_acordo_id := 0;
  v_lbl_job         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_num_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do ' || v_lbl_job || ' não informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(job_id)
    INTO v_job_id
    FROM job
   WHERE numero = TRIM(p_num_job)
     AND empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe (' || p_num_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_num_carta_acordo) IS NULL OR inteiro_validar(p_num_carta_acordo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da carta acordo inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ca.carta_acordo_id)
    INTO v_carta_acordo_id
    FROM carta_acordo ca
   WHERE job_id = v_job_id
     AND num_carta_acordo = to_number(p_num_carta_acordo);
  --
  IF v_carta_acordo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe nesse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  p_carta_acordo_id := v_carta_acordo_id;
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
  
 END; -- id_retornar
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 09/02/2017
  -- DESCRICAO: Subrotina que gera o xml da carta acordo para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/06/2018  Grava flag_fornec_interno.
  ------------------------------------------------------------------------------------------
 (
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
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
  v_valor_bv  NUMBER(22, 2);
  v_valor_tip NUMBER(22, 2);
  --
  CURSOR c_pa IS
   SELECT num_parcela,
          data_mostrar(data_parcela) data_parcela,
          numero_mostrar(valor_parcela, 2, 'N') valor_parcela,
          to_char(num_dias) num_dias,
          tipo_num_dias
     FROM parcela_carta
    WHERE carta_acordo_id = p_carta_acordo_id
    ORDER BY num_parcela;
  --
  CURSOR c_it IS
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || '/' || it.tipo_item ||
          to_char(it.num_seq) AS num_item,
          numero_mostrar(ia.valor_aprovado, 2, 'N') valor_aprovado,
          numero_mostrar(ia.valor_fornecedor, 2, 'N') valor_fornecedor,
          numero_mostrar(ia.quantidade, 2, 'N') quantidade,
          numero_mostrar(ia.frequencia, 2, 'N') frequencia,
          numero_mostrar(ia.custo_unitario, 5, 'N') custo_unitario,
          TRIM(tp.nome || ' ' || ia.complemento) produto_comprado
     FROM item_carta   ia,
          item         it,
          tipo_produto tp
    WHERE ia.carta_acordo_id = p_carta_acordo_id
      AND ia.item_id = it.item_id
      AND ia.tipo_produto_id = tp.tipo_produto_id(+)
    ORDER BY 1;
  --
  CURSOR c_ec IS
   SELECT ec.data_email,
          ec.email_carta_id,
          data_hora_mostrar(ec.data_email) data_email_char,
          pe.apelido AS responsavel,
          ec.enviar_para
     FROM email_carta ec,
          pessoa      pe
    WHERE ec.carta_acordo_id = p_carta_acordo_id
      AND ec.usuario_resp_id = pe.usuario_id(+)
    ORDER BY 1,
             2;
  --
  CURSOR c_ap IS
   SELECT cf.seq_aprov,
          pa.nome AS papel,
          data_hora_mostrar(cf.data_aprov) data_aprov_char,
          pe.apelido AS aprovador
     FROM carta_fluxo_aprov cf,
          pessoa            pe,
          papel             pa
    WHERE cf.carta_acordo_id = p_carta_acordo_id
      AND cf.usuario_aprov_id = pe.usuario_id(+)
      AND cf.papel_id = pa.papel_id(+)
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  v_valor_bv  := carta_acordo_pkg.valor_retornar(p_carta_acordo_id, 'BV');
  v_valor_tip := carta_acordo_pkg.valor_retornar(p_carta_acordo_id, 'TIP');
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("carta_acordo_id", ca.carta_acordo_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("num_carta_acordo", ca.num_carta_formatado),
                   xmlelement("cod_ext_carta", ca.cod_ext_carta),
                   xmlelement("status", ca.status),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("fornecedor", po.apelido),
                   xmlelement("contato_fornec", nvl(co.apelido, ca.contato_fornec)),
                   xmlelement("empresa_fatur", pf.apelido),
                   xmlelement("produtor", pd.apelido),
                   xmlelement("elaborador", pe.apelido),
                   xmlelement("valor_aprovado", numero_mostrar(ca.valor_aprovado, 2, 'S')),
                   xmlelement("valor_fornecedor", numero_mostrar(ca.valor_fornecedor, 2, 'S')),
                   xmlelement("perc_bv", numero_mostrar(ca.perc_bv, 5, 'N')),
                   xmlelement("perc_imposto", numero_mostrar(ca.perc_imposto, 2, 'N')),
                   xmlelement("valor_bv", numero_mostrar(v_valor_bv, 2, 'N')),
                   xmlelement("valor_tip", numero_mostrar(v_valor_tip, 2, 'N')),
                   xmlelement("tipo_fatur_bv", ca.tipo_fatur_bv),
                   xmlelement("valor_credito_usado", numero_mostrar(ca.valor_credito_usado, 2, 'S')),
                   xmlelement("data_criacao", data_hora_mostrar(ca.data_criacao)),
                   xmlelement("data_aprovacao", data_hora_mostrar(ca.data_aprovacao)),
                   xmlelement("faixa_aprov_id", to_char(ca.faixa_aprov_id)),
                   xmlelement("data_emissao", data_hora_mostrar(ca.data_emissao)),
                   xmlelement("data_envio", data_hora_mostrar(ca.data_envio)),
                   xmlelement("tipo_envio", ca.tipo_envio),
                   xmlelement("data_aceite", data_hora_mostrar(ca.data_aceite)),
                   xmlelement("usuario_aceite", pa.apelido),
                   xmlelement("status_aceite", ca.status_aceite),
                   xmlelement("modo_pagto", ca.modo_pagto),
                   xmlelement("banco_fornec", ba.nome),
                   xmlelement("num_agencia", ca.num_agencia),
                   xmlelement("num_conta", ca.num_conta),
                   xmlelement("tipo_conta", ca.tipo_conta),
                   xmlelement("mostrar_aos_cuidados", ca.flag_mostrar_ac),
                   xmlelement("fornecedor_homolog", ca.flag_fornec_homolog),
                   xmlelement("fornecedor_interno", po.flag_fornec_interno),
                   xmlelement("nivel_excelencia", numero_mostrar(ca.nivel_excelencia, 2, 'N')),
                   xmlelement("nivel_parceria", numero_mostrar(ca.nivel_parceria, 2, 'N')),
                   xmlelement("com_aprovacao", ca.flag_com_aprov),
                   xmlelement("aprovacao_seq", ca.flag_aprov_seq),
                   xmlelement("com_produto_comprado", ca.flag_com_prodcomp))
    INTO v_xml
    FROM carta_acordo ca,
         pessoa       cl,
         pessoa       po,
         pessoa       pf,
         pessoa       pd,
         pessoa       pe,
         pessoa       pa,
         pessoa       co,
         fi_banco     ba
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.fornecedor_id = po.pessoa_id
     AND ca.cliente_id = cl.pessoa_id
     AND ca.emp_faturar_por_id = pf.pessoa_id
     AND ca.produtor_id = pd.usuario_id(+)
     AND ca.elaborador_id = pe.pessoa_id(+)
     AND ca.usuario_acei_id = pa.usuario_id(+)
     AND ca.contato_fornec_id = co.pessoa_id(+)
     AND fi_banco_fornec_id = ba.fi_banco_id(+);
  --
  ------------------------------------------------------------
  -- monta ENVIO_EMAIL
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ec IN c_ec
  LOOP
   SELECT xmlagg(xmlelement("envio_email",
                            xmlelement("data_envio", r_ec.data_email_char),
                            xmlelement("responsavel", r_ec.responsavel),
                            xmlelement("enviar_para", r_ec.enviar_para)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("envios_email", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta APROVACAO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ap IN c_ap
  LOOP
   SELECT xmlagg(xmlelement("aprovacao",
                            xmlelement("sequencia", r_ap.seq_aprov),
                            xmlelement("papel", r_ap.papel),
                            xmlelement("data_aprovacao", r_ap.data_aprov_char),
                            xmlelement("aprovador", r_ap.aprovador)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("aprovacoes", v_xml_aux1))
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
   IF r_pa.data_parcela IS NOT NULL
   THEN
    SELECT xmlagg(xmlelement("parcela",
                             xmlelement("num_parcela", r_pa.num_parcela),
                             xmlelement("data_parcela", r_pa.data_parcela),
                             xmlelement("valor_parcela", r_pa.valor_parcela)))
      INTO v_xml_aux99
      FROM dual;
   
   ELSE
    SELECT xmlagg(xmlelement("parcela",
                             xmlelement("num_parcela", r_pa.num_parcela),
                             xmlelement("num_dias", r_pa.num_dias),
                             xmlelement("tipo_num_dias", r_pa.tipo_num_dias),
                             xmlelement("valor_parcela", r_pa.valor_parcela)))
      INTO v_xml_aux99
      FROM dual;
   
   END IF;
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
  -- monta ITENS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_it IN c_it
  LOOP
   SELECT xmlagg(xmlelement("item",
                            xmlelement("num_item", r_it.num_item),
                            xmlelement("valor_aprovado", r_it.valor_aprovado),
                            xmlelement("valor_fornecedor", r_it.valor_fornecedor),
                            xmlelement("produto_comprado", r_it.produto_comprado)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("itens", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "carta_acordo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("carta_acordo", v_xml))
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
 FUNCTION tipo_fatur_bv_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: retorna o tipo de faturamento do BV (FAT ou ABA) correspondente a uma
  --  determinada carta_acordo. Caso isso não se aplique (não tem TIP nem BV), retorna
  --  o código 'NA'.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN VARCHAR2 AS
 
  v_qt               INTEGER;
  v_retorno          VARCHAR2(20);
  v_tipo_fatur_bv    item.tipo_fatur_bv%TYPE;
  v_valor_aprovado   item.valor_aprovado%TYPE;
  v_valor_fornecedor item.valor_fornecedor%TYPE;
  v_perc_bv          item.perc_bv%TYPE;
  --
 BEGIN
  --
  SELECT tipo_fatur_bv,
         nvl(valor_aprovado, 0),
         nvl(valor_fornecedor, 0),
         nvl(perc_bv, 0)
    INTO v_tipo_fatur_bv,
         v_valor_aprovado,
         v_valor_fornecedor,
         v_perc_bv
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF (v_valor_aprovado - v_valor_fornecedor) > 0 OR v_perc_bv > 0
  THEN
   v_retorno := v_tipo_fatur_bv;
  ELSE
   v_retorno := 'NA';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END tipo_fatur_bv_retornar;
 --
 --
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 16/01/2008
  -- DESCRICAO: retorna o numero formatado de uma determinada carta acordo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN VARCHAR2 AS
 
  v_retorno          VARCHAR2(100);
  v_qt               INTEGER;
  v_num_job          job.numero%TYPE;
  v_job_id           job.job_id%TYPE;
  v_num_carta_acordo carta_acordo.num_carta_acordo%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         jo.job_id,
         ca.num_carta_acordo
    INTO v_num_job,
         v_job_id,
         v_num_carta_acordo
    FROM carta_acordo ca,
         job          jo
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.job_id = jo.job_id(+);
  --
  IF v_job_id IS NOT NULL
  THEN
   -- carta monojob
   IF length(v_num_carta_acordo) <= 3
   THEN
    v_retorno := 'CA' || TRIM(to_char(v_num_carta_acordo, '000'));
   ELSE
    v_retorno := 'CA' || to_char(v_num_carta_acordo);
   END IF;
  ELSE
   -- carta multijob
   IF length(v_num_carta_acordo) <= 4
   THEN
    v_retorno := TRIM(to_char(v_num_carta_acordo, '0000'));
   ELSE
    v_retorno := to_char(v_num_carta_acordo);
   END IF;
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
 FUNCTION numero_completo_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 21/10/2013
  -- DESCRICAO: retorna o numero completo formatado de uma determinada carta acordo (com
  --  numero do job ou sigla multijob e prefixo CA/AO(opcional).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         26/03/2025  Alterado verificacao de prefixo, para adicionar antes do job
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_flag_prefixo    IN VARCHAR2
 ) RETURN VARCHAR2 AS
 
  v_retorno          VARCHAR2(100);
  v_num_formatado    VARCHAR2(100);
  v_qt               INTEGER;
  v_num_job          job.numero%TYPE;
  v_job_id           job.job_id%TYPE;
  v_num_carta_acordo carta_acordo.num_carta_acordo%TYPE;
  v_empresa_id       pessoa.empresa_id%TYPE;
  v_sigla_multijob   VARCHAR2(100);
  v_prefixo          VARCHAR2(10);
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         jo.job_id,
         ca.num_carta_acordo,
         decode(ca.status, 'EMEMIS', 'CA', 'EMITIDA', 'CA', 'AO'),
         pe.empresa_id
    INTO v_num_job,
         v_job_id,
         v_num_carta_acordo,
         v_prefixo,
         v_empresa_id
    FROM carta_acordo ca,
         job          jo,
         pessoa       pe
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.cliente_id = pe.pessoa_id
     AND ca.job_id = jo.job_id(+);
  --
  IF v_job_id IS NOT NULL
  THEN
   -- carta monojob
   IF length(v_num_carta_acordo) <= 3
   THEN
    v_num_formatado := TRIM(to_char(v_num_carta_acordo, '000'));
   ELSE
    v_num_formatado := to_char(v_num_carta_acordo);
   END IF;
  ELSE
   -- carta multijob
   IF length(v_num_carta_acordo) <= 4
   THEN
    v_num_formatado := TRIM(to_char(v_num_carta_acordo, '0000'));
   ELSE
    v_num_formatado := to_char(v_num_carta_acordo);
   END IF;
   --
   v_sigla_multijob := empresa_pkg.parametro_retornar(v_empresa_id, 'CA_SIGLA_MULTIJOB');
  END IF;
  --ALCBO_260325 - ADICIONADO AQUI
  IF p_flag_prefixo = 'S'
  THEN
   v_num_formatado := v_prefixo || v_num_formatado;
  END IF;
  --
  IF v_num_job IS NOT NULL
  THEN
   v_num_formatado := v_num_job || '-' || v_num_formatado;
  ELSE
   v_num_formatado := v_sigla_multijob || '-' || v_num_formatado;
  END IF;
  --
  --ALCBO_260325 - REMOVIDO DAQUI
  --
  v_retorno := v_num_formatado;
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_completo_formatar;
 --
 --
 FUNCTION num_orcam_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 22/01/2008
  -- DESCRICAO: retorna o numero formatado dos orcamentos que integram uma determinada
  --   carta acordo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN VARCHAR2 AS
 
  v_retorno VARCHAR2(1000);
  v_qt      INTEGER;
  --
  CURSOR c_orc IS
   SELECT DISTINCT it.orcamento_id,
                   orcamento_pkg.numero_formatar(it.orcamento_id) AS num_orcam
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id
    ORDER BY it.orcamento_id;
  --
 BEGIN
  v_retorno := NULL;
  --
  FOR r_orc IN c_orc
  LOOP
   v_retorno := v_retorno || ', ' || r_orc.num_orcam;
  END LOOP;
  --
  -- retira a primeira virgula
  v_retorno := substr(v_retorno, 3);
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END num_orcam_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/02/2008
  -- DESCRICAO: retorna o valor planejado de uma determinada carta acordo, de acordo
  --  com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/04/2008  Tratamento das sobras.
  -- Silvia            30/10/2020  Novo flag_dentro_ca (sobra)
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER AS
 
  v_qt               INTEGER;
  v_retorno          NUMBER;
  v_exception        EXCEPTION;
  v_valor_aprovado   item.valor_aprovado%TYPE;
  v_valor_fornecedor item.valor_fornecedor%TYPE;
  v_perc_bv          item.perc_bv%TYPE;
  v_perc_imposto     item.perc_imposto%TYPE;
  v_valor_com_nf     NUMBER;
  v_valor_sobra      NUMBER;
  v_valor_abat       NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN ('APROVADO',
                          'FORNECEDOR',
                          'BV',
                          'IMPOSTO',
                          'TIP',
                          'PERC_BV',
                          'PERC_IMPOSTO',
                          'COM_NF',
                          'SEM_NF',
                          'SOBRA',
                          'ABATIMENTO') OR TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0)
    INTO v_valor_aprovado,
         v_valor_fornecedor,
         v_perc_bv,
         v_perc_imposto
    FROM carta_acordo ca
   WHERE ca.carta_acordo_id = p_carta_acordo_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_com_nf
    FROM item_nota
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  SELECT nvl(SUM(it.valor_sobra_item), 0)
    INTO v_valor_sobra
    FROM item_sobra it,
         sobra      so
   WHERE it.sobra_id = so.sobra_id
     AND so.carta_acordo_id = p_carta_acordo_id
     AND so.flag_dentro_ca = 'S';
  --
  SELECT nvl(SUM(it.valor_abat_item), 0)
    INTO v_valor_abat
    FROM item_abat  it,
         abatimento ab
   WHERE it.abatimento_id = ab.abatimento_id
     AND ab.carta_acordo_id = p_carta_acordo_id;
  --
  IF p_tipo_valor = 'APROVADO'
  THEN
   v_retorno := v_valor_aprovado;
  ELSIF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornecedor;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := round(v_valor_fornecedor * v_perc_bv / 100, 2);
  ELSIF p_tipo_valor = 'IMPOSTO'
  THEN
   v_retorno := round((v_valor_aprovado - v_valor_fornecedor) * v_perc_imposto / 100, 2);
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := round((v_valor_aprovado - v_valor_fornecedor) * (1 - v_perc_imposto / 100), 2);
  ELSIF p_tipo_valor = 'PERC_BV'
  THEN
   v_retorno := v_perc_bv;
  ELSIF p_tipo_valor = 'PERC_IMPOSTO'
  THEN
   v_retorno := v_perc_imposto;
  ELSIF p_tipo_valor = 'COM_NF'
  THEN
   v_retorno := v_valor_com_nf;
  ELSIF p_tipo_valor = 'SEM_NF'
  THEN
   v_retorno := v_valor_aprovado - v_valor_com_nf - v_valor_sobra;
  ELSIF p_tipo_valor = 'SOBRA'
  THEN
   v_retorno := v_valor_sobra;
  ELSIF p_tipo_valor = 'ABATIMENTO'
  THEN
   v_retorno := v_valor_abat;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION resultado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 04/03/2020
  -- DESCRICAO: retorna o resultado da carta acordo (bv+tip)/valor carta
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/10/2020  Inclusao da sobra no resultado
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN NUMBER AS
 
  v_qt               INTEGER;
  v_retorno          NUMBER;
  v_exception        EXCEPTION;
  v_valor_aprovado   item.valor_aprovado%TYPE;
  v_valor_fornecedor item.valor_fornecedor%TYPE;
  v_perc_bv          item.perc_bv%TYPE;
  v_perc_imposto     item.perc_imposto%TYPE;
  v_valor_bv         NUMBER;
  v_valor_tip        NUMBER;
  v_valor_sobra      NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0)
    INTO v_valor_aprovado,
         v_valor_fornecedor,
         v_perc_bv,
         v_perc_imposto
    FROM carta_acordo ca
   WHERE ca.carta_acordo_id = p_carta_acordo_id;
  --
  -- nao pega as sobras indicadas dentro da CA
  SELECT nvl(SUM(it.valor_sobra_item), 0)
    INTO v_valor_sobra
    FROM item_sobra it,
         sobra      so
   WHERE it.sobra_id = so.sobra_id
     AND so.carta_acordo_id = p_carta_acordo_id
     AND so.flag_dentro_ca = 'N';
  --
  v_valor_bv  := round(v_valor_fornecedor * v_perc_bv / 100, 2);
  v_valor_tip := round((v_valor_aprovado - v_valor_fornecedor) * (1 - v_perc_imposto / 100), 2);
  --
  v_retorno := round((v_valor_bv + v_valor_tip + v_valor_sobra) / v_valor_aprovado * 100, 2);
 
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END resultado_retornar;
 --
 --
 FUNCTION legenda_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: retorna o codigo do tipo de legenda a ser mostrado na interface de cartas
  --   acordo da estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN VARCHAR2 AS
 
  v_qt         INTEGER;
  v_retorno    VARCHAR2(20);
  v_status_ca  carta_acordo.status%TYPE;
  v_data_envio carta_acordo.data_envio%TYPE;
  --
 BEGIN
  v_retorno := 'OK';
  --
  SELECT status,
         data_envio
    INTO v_status_ca,
         v_data_envio
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_status_ca <> 'EMITIDA'
  THEN
   v_retorno := 'NAOEMI';
  ELSIF v_data_envio IS NULL
  THEN
   v_retorno := 'NAOENV';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END legenda_retornar;
 --
 --
 FUNCTION faixa_aprov_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/12/2013
  -- DESCRICAO: verifica se o usuario pode aprovar AO com esse valor.
  --  Retorna 1 caso possa e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/05/2015  Ajuste em teste de sequencia de aprovacao.
  ------------------------------------------------------------------------------------------
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER AS
 
  v_qt              INTEGER;
  v_retorno         INTEGER;
  v_ok              INTEGER;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_valor_aprovado  carta_acordo.valor_aprovado%TYPE;
  v_flag_aprov_seq  carta_acordo.flag_aprov_seq%TYPE;
  v_flag_admin      usuario.flag_admin%TYPE;
  v_aprova_faixa    VARCHAR2(20);
  v_valor_sem_aprov NUMBER;
  v_tipo_item1      item.tipo_item%TYPE;
  v_tipo_item2      item.tipo_item%TYPE;
  v_seq_aprov       carta_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_maior carta_fluxo_aprov.seq_aprov%TYPE;
  v_faixa_aprov_id  faixa_aprov.faixa_aprov_id%TYPE;
  --
 BEGIN
  v_retorno      := 0;
  v_aprova_faixa := empresa_pkg.parametro_retornar(p_empresa_id, 'AO_APROVA_FAIXA');
  --
  ------------------------------------------------------------
  -- verifica casos especiais
  ------------------------------------------------------------
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_flag_admin = 'S'
  THEN
   -- eh o usuario admin, nao tem fluxo
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  v_valor_sem_aprov := nvl(moeda_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'AO_VALOR_SEM_APROV')),
                           0);
  --
  SELECT nvl(valor_aprovado, 0),
         flag_aprov_seq
    INTO v_valor_aprovado,
         v_flag_aprov_seq
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_aprova_faixa = 'N' OR v_valor_aprovado <= v_valor_sem_aprov
  THEN
   -- empresa nao tem aprovacao por faixa ou AO c/ valor baixo (s/ necessidade de aprov)
   -- testa apenas o privilegio.
   v_ok := usuario_pkg.priv_verificar(p_usuario_id,
                                      'CARTA_ACORDO_AP',
                                      NULL,
                                      p_carta_acordo_id,
                                      p_empresa_id);
   --
   IF v_ok = 1
   THEN
    v_retorno := 1;
   END IF;
   --
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- verifica se o fluxo de aprovacao ja foi instanciado
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_fluxo_aprov
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt > 0
  THEN
   -- existe um fluxo em andamento.
   IF v_flag_aprov_seq = 'S'
   THEN
    -- aprovacao deve obedecer a sequencia.
    -- pega a maior sequencia aprovada
    SELECT nvl(MAX(seq_aprov), 0)
      INTO v_seq_aprov_maior
      FROM carta_fluxo_aprov
     WHERE carta_acordo_id = p_carta_acordo_id
       AND data_aprov IS NOT NULL;
    --
    -- pega a proxima sequencia com aprovacao pendente
    SELECT nvl(MIN(seq_aprov), 0)
      INTO v_seq_aprov
      FROM carta_fluxo_aprov
     WHERE carta_acordo_id = p_carta_acordo_id
       AND data_aprov IS NULL
       AND seq_aprov > v_seq_aprov_maior;
    --
    -- Verifica se algum papel do usuario pode aprovar nessa sequencia.
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_papel up
     WHERE up.usuario_id = p_usuario_id
       AND carta_acordo_pkg.papel_priv_verificar(up.usuario_id,
                                                 'CARTA_ACORDO_AP',
                                                 up.papel_id,
                                                 p_carta_acordo_id) = 1
       AND EXISTS (SELECT 1
              FROM carta_fluxo_aprov cf
             WHERE cf.carta_acordo_id = p_carta_acordo_id
               AND cf.papel_id = up.papel_id
               AND cf.seq_aprov = v_seq_aprov
               AND cf.data_aprov IS NULL);
    --
    IF v_qt > 0
    THEN
     v_retorno := 1;
     RAISE v_saida;
    END IF;
   ELSE
    -- aprovacao nao precisa obedecer a sequencia. Verifica se algum papel do
    -- usuario pode aprovar em qualquer sequencia ainda nao aprovada.
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_papel     up,
           carta_fluxo_aprov cf
     WHERE up.usuario_id = p_usuario_id
       AND carta_acordo_pkg.papel_priv_verificar(up.usuario_id,
                                                 'CARTA_ACORDO_AP',
                                                 up.papel_id,
                                                 p_carta_acordo_id) = 1
       AND cf.carta_acordo_id = p_carta_acordo_id
       AND cf.papel_id = up.papel_id
       AND cf.data_aprov IS NULL
       AND NOT EXISTS (SELECT 1
              FROM carta_fluxo_aprov c2
             WHERE c2.carta_acordo_id = cf.carta_acordo_id
               AND c2.seq_aprov = cf.seq_aprov
               AND c2.data_aprov IS NOT NULL);
    --
    IF v_qt > 0
    THEN
     v_retorno := 1;
     RAISE v_saida;
    END IF;
   END IF;
   --
   -- forca a saida com retorno 0 (usuario sem permissao)
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- nao tem fluxo instanciado.
  -- verifica fluxos de aprovacao configurados
  ------------------------------------------------------------
  v_faixa_aprov_id := carta_acordo_pkg.faixa_aprov_id_retornar(p_usuario_id,
                                                               p_empresa_id,
                                                               p_carta_acordo_id);
  --
  IF v_faixa_aprov_id < 0
  THEN
   -- forca a saida com retorno 0 (usuario sem permissao)
   v_retorno := 0;
   RAISE v_saida;
  END IF;
  --
  IF v_faixa_aprov_id = 0
  THEN
   -- forca a saida com retorno 1 (usuario ADMIN)
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  SELECT flag_sequencial
    INTO v_flag_aprov_seq
    FROM faixa_aprov
   WHERE faixa_aprov_id = v_faixa_aprov_id;
  --
  IF v_flag_aprov_seq = 'N'
  THEN
   -- nao precisa verificar a sequencia
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  -- verifica a sequencia (primeiro aprovador)
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_papel fa,
         usuario_papel     up
   WHERE fa.faixa_aprov_id = v_faixa_aprov_id
     AND fa.seq_aprov = 1
     AND fa.papel_id = up.papel_id
     AND up.usuario_id = p_usuario_id;
  --
  IF v_qt > 0
  THEN
   -- usuario tem papel para ser o primeiro aprovador
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END faixa_aprov_verificar;
 --
 --
 FUNCTION faixa_aprov_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/12/2013
  -- DESCRICAO: verifica se o usuario pode aprovar AO com esse valor, retornando o
  --   respectivo faixa_aprov_id. Retorno -1 indica faixa nao encontrada. Retorno 0 indica
  --   usuario sem necessidade de faixa de aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/11/2015  Cursor para pegar a faixa de menor sequencia.
  --                               Teste fornec homolog.
  -- Silvia            11/10/2016  Aceita usuario_id = 0 (retorna qualquer faixa que sirva)
  -- Silvia            27/10/2016  Ordenacao do cursor p/ regras mais especificas.
  -- Silvia            16/11/2017  Implementacao de flag_ativo.
  -- Silvia            08/06/2018  Teste fornec interno.
  -- Silvia            04/03/2020  Teste de resultado.
  -- Ana Luiza         06/08/2028  Tratativa para voltar o ultimo registro da tab pessoa_homolog
  ------------------------------------------------------------------------------------------
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN NUMBER AS
 
  v_qt                  INTEGER;
  v_faixa_aprov_id      faixa_aprov.faixa_aprov_id%TYPE;
  v_exception           EXCEPTION;
  v_saida               EXCEPTION;
  v_valor_aprovado      carta_acordo.valor_aprovado%TYPE;
  v_cliente_id          carta_acordo.cliente_id%TYPE;
  v_flag_fornec_homolog CHAR(1);
  v_resultado           NUMBER;
  v_flag_fornec_interno pessoa.flag_fornec_interno%TYPE;
  v_flag_admin          usuario.flag_admin%TYPE;
  v_aprova_faixa        VARCHAR2(20);
  v_valor_sem_aprov     NUMBER;
  v_tipo_item1          item.tipo_item%TYPE;
  v_tipo_item2          item.tipo_item%TYPE;
  --
  CURSOR c_fa IS
  -- faixas para itens de A (que sevem para o usuario)
  -- (com preferencia para as regras mais especificas)
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov       fa,
          faixa_aprov_papel fp,
          faixa_aprov_ao    fo
    WHERE fa.empresa_id = p_empresa_id
      AND fa.tipo_faixa = 'AO'
      AND fa.flag_ativo = 'S'
      AND fa.faixa_aprov_id = fo.faixa_aprov_id
      AND fo.flag_itens_a = 'S'
      AND v_valor_aprovado BETWEEN fo.valor_de AND nvl(fo.valor_ate, 99999999999999999999)
      AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
      AND (fo.fornec_homolog = 'A' OR fo.fornec_homolog = v_flag_fornec_homolog)
      AND (fo.fornec_interno = 'A' OR fo.fornec_interno = v_flag_fornec_interno)
      AND (fo.resultado_de IS NULL OR v_resultado BETWEEN fo.resultado_de AND fo.resultado_ate)
      AND fa.faixa_aprov_id = fp.faixa_aprov_id
      AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
    ORDER BY decode(fo.cliente_id, NULL, 999, 1),
             decode(fo.fornec_homolog, 'A', 999, 1),
             fp.seq_aprov,
             fa.faixa_aprov_id;
  --
  CURSOR c_fb IS
  -- faixas para itens de B e C (que sevem para o usuario)
  -- (com preferencia para as regras mais especificas)
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov       fa,
          faixa_aprov_papel fp,
          faixa_aprov_ao    fo
    WHERE fa.empresa_id = p_empresa_id
      AND fa.tipo_faixa = 'AO'
      AND fa.flag_ativo = 'S'
      AND fa.faixa_aprov_id = fo.faixa_aprov_id
      AND fo.flag_itens_bc = 'S'
      AND v_valor_aprovado BETWEEN fo.valor_de AND nvl(fo.valor_ate, 99999999999999999999)
      AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
      AND (fo.fornec_homolog = 'A' OR fo.fornec_homolog = v_flag_fornec_homolog)
      AND (fo.fornec_interno = 'A' OR fo.fornec_interno = v_flag_fornec_interno)
      AND (fo.resultado_de IS NULL OR v_resultado BETWEEN fo.resultado_de AND fo.resultado_ate)
      AND fa.faixa_aprov_id = fp.faixa_aprov_id
      AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
    ORDER BY decode(fo.cliente_id, NULL, 999, 1),
             decode(fo.fornec_homolog, 'A', 999, 1),
             fp.seq_aprov,
             fa.faixa_aprov_id;
  --
 BEGIN
  v_faixa_aprov_id := -1;
  v_aprova_faixa   := empresa_pkg.parametro_retornar(p_empresa_id, 'AO_APROVA_FAIXA');
  v_flag_admin     := 'N';
  --
  IF nvl(p_usuario_id, 0) > 0
  THEN
   SELECT flag_admin
     INTO v_flag_admin
     FROM usuario
    WHERE usuario_id = p_usuario_id;
  
  END IF;
  --
  IF v_aprova_faixa = 'N' OR v_flag_admin = 'S'
  THEN
   -- empresa nao tem aprovacao por faixa ou eh o usuario admin
   v_faixa_aprov_id := 0;
   RAISE v_saida;
  END IF;
  --
  v_valor_sem_aprov := nvl(moeda_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'AO_VALOR_SEM_APROV')),
                           0);
  --
  SELECT nvl(ca.valor_aprovado, 0),
         ca.cliente_id,
         decode(ph.status_para, 'NAPL', 'S', 'HMLG', 'S', 'N'),
         pf.flag_fornec_interno,
         carta_acordo_pkg.resultado_retornar(ca.carta_acordo_id)
    INTO v_valor_aprovado,
         v_cliente_id,
         v_flag_fornec_homolog,
         v_flag_fornec_interno,
         v_resultado
    FROM carta_acordo ca
    JOIN pessoa pf
      ON ca.fornecedor_id = pf.pessoa_id
    LEFT JOIN pessoa_homolog ph
      ON pf.pessoa_id = ph.pessoa_id
     AND ph.flag_atual = 'S'
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ph.data_hora = (SELECT MAX(data_hora)
                           FROM pessoa_homolog
                          WHERE pessoa_id = pf.pessoa_id); --ALCBO_060825;
  --
  IF v_valor_aprovado <= v_valor_sem_aprov
  THEN
   v_faixa_aprov_id := 0;
   RAISE v_saida;
  END IF;
  --
  -- verifica o tipo dos itens da carta acordo
  SELECT MIN(tipo_item),
         MAX(tipo_item)
    INTO v_tipo_item1,
         v_tipo_item2
    FROM item_carta ic,
         item       it
   WHERE ic.carta_acordo_id = p_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  IF v_tipo_item1 = 'A' AND v_tipo_item2 = 'A'
  THEN
   -- carta acordo com itens de A
   FOR r_fa IN c_fa
   LOOP
    -- pega a primeira faixa encontrada. Se nao achar nada,
    -- a variavel continua com o valor -1.
    IF v_faixa_aprov_id = -1
    THEN
     IF nvl(p_usuario_id, 0) > 0
     THEN
      IF carta_acordo_pkg.papel_priv_verificar(p_usuario_id,
                                               'CARTA_ACORDO_AP',
                                               r_fa.papel_id,
                                               p_carta_acordo_id) = 1
      THEN
       v_faixa_aprov_id := r_fa.faixa_aprov_id;
      END IF;
     
     ELSE
      v_faixa_aprov_id := r_fa.faixa_aprov_id;
     END IF;
    
    END IF;
   END LOOP;
  ELSE
   -- carta acordo com itens de B/C
   FOR r_fb IN c_fb
   LOOP
    -- pega a primeira faixa encontrada. Se nao achar nada,
    -- a variavel continua com o valor -1.
    IF v_faixa_aprov_id = -1
    THEN
     IF nvl(p_usuario_id, 0) > 0
     THEN
      IF carta_acordo_pkg.papel_priv_verificar(p_usuario_id,
                                               'CARTA_ACORDO_AP',
                                               r_fb.papel_id,
                                               p_carta_acordo_id) = 1
      THEN
       v_faixa_aprov_id := r_fb.faixa_aprov_id;
      END IF;
     
     ELSE
      v_faixa_aprov_id := r_fb.faixa_aprov_id;
     END IF;
    
    END IF;
   END LOOP;
  END IF; -- fim do IF v_tipo_item1
  --
  RETURN v_faixa_aprov_id;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_faixa_aprov_id;
  WHEN OTHERS THEN
   v_faixa_aprov_id := -1;
   RETURN v_faixa_aprov_id;
 END faixa_aprov_id_retornar;
 --
 --
 FUNCTION usuario_aprov_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 25/11/2014
  -- DESCRICAO: verifica se existe algum usuario que pode aprovar essa AO.
  --  Retorna 1 caso possa e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/11/2015  Teste fornec homolog.
  -- Silvia            16/11/2017  Implementacao de flag_ativo.
  -- Silvia            08/06/2018  Teste fornec interno.
  ------------------------------------------------------------------------------------------
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER AS
 
  v_qt                  INTEGER;
  v_retorno             INTEGER;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_valor_aprovado      carta_acordo.valor_aprovado%TYPE;
  v_cliente_id          carta_acordo.cliente_id%TYPE;
  v_flag_fornec_homolog CHAR(1);
  v_flag_fornec_interno pessoa.flag_fornec_interno%TYPE;
  v_aprova_faixa        VARCHAR2(20);
  v_valor_sem_aprov     NUMBER;
  v_tipo_item1          item.tipo_item%TYPE;
  v_tipo_item2          item.tipo_item%TYPE;
  --
 BEGIN
  v_retorno         := 0;
  v_aprova_faixa    := empresa_pkg.parametro_retornar(p_empresa_id, 'AO_APROVA_FAIXA');
  v_valor_sem_aprov := nvl(moeda_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'AO_VALOR_SEM_APROV')),
                           0);
  --
  -- o job_id de carta multijob vem nulo
  SELECT ca.job_id,
         nvl(ca.valor_aprovado, 0),
         ca.cliente_id,
         decode(ph.status_para, 'NAPL', 'S', 'HMLG', 'S', 'N'),
         pf.flag_fornec_interno
    INTO v_job_id,
         v_valor_aprovado,
         v_cliente_id,
         v_flag_fornec_homolog,
         v_flag_fornec_interno
    FROM carta_acordo   ca,
         pessoa         pf,
         pessoa_homolog ph
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.fornecedor_id = pf.pessoa_id
     AND pf.pessoa_id = ph.pessoa_id(+)
     AND ph.flag_atual(+) = 'S';
  --
  IF v_aprova_faixa = 'N'
  THEN
   -- empresa nao tem aprovacao por faixa de valores. Verifica apenas os privilegios.
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE flag_admin = 'N'
      AND flag_ativo = 'S'
      AND usuario_pkg.priv_verificar(usuario_id,
                                     'CARTA_ACORDO_AP',
                                     NULL,
                                     p_carta_acordo_id,
                                     p_empresa_id) = 1;
   --
   IF v_qt > 0
   THEN
    -- existe usuario habilitado.
    v_retorno := 1;
   END IF;
  ELSE
   -- empresa tem aprovacao por faixa de valores. Verifica valores e privilegios.
   IF v_valor_aprovado <= v_valor_sem_aprov
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario
     WHERE flag_admin = 'N'
       AND flag_ativo = 'S'
       AND usuario_pkg.priv_verificar(usuario_id,
                                      'CARTA_ACORDO_AP',
                                      NULL,
                                      p_carta_acordo_id,
                                      p_empresa_id) = 1;
    --
    IF v_qt > 0
    THEN
     -- existe usuario habilitado.
     v_retorno := 1;
    END IF;
   ELSE
    -- verifica o tipo dos itens da carta acordo
    SELECT MIN(tipo_item),
           MAX(tipo_item)
      INTO v_tipo_item1,
           v_tipo_item2
      FROM item_carta ic,
           item       it
     WHERE ic.carta_acordo_id = p_carta_acordo_id
       AND ic.item_id = it.item_id;
    --
    IF v_tipo_item1 = 'A' AND v_tipo_item2 = 'A'
    THEN
     -- carta acordo com itens de A
     SELECT COUNT(*)
       INTO v_qt
       FROM faixa_aprov       fa,
            faixa_aprov_papel fp,
            faixa_aprov_ao    fo
      WHERE fa.empresa_id = p_empresa_id
        AND fa.tipo_faixa = 'AO'
        AND fa.flag_ativo = 'S'
        AND fa.faixa_aprov_id = fo.faixa_aprov_id
        AND fo.flag_itens_a = 'S'
        AND v_valor_aprovado BETWEEN fo.valor_de AND nvl(fo.valor_ate, 99999999999999999999)
        AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
        AND (fo.fornec_homolog = 'A' OR fo.fornec_homolog = v_flag_fornec_homolog)
        AND (fo.fornec_interno = 'A' OR fo.fornec_interno = v_flag_fornec_interno)
        AND fa.faixa_aprov_id = fp.faixa_aprov_id
        AND EXISTS (SELECT 1
               FROM usuario_papel up,
                    usuario       us
              WHERE up.papel_id = fp.papel_id
                AND up.usuario_id = us.usuario_id
                AND us.flag_admin = 'N'
                AND us.flag_ativo = 'S'
                AND usuario_pkg.priv_verificar(us.usuario_id,
                                               'CARTA_ACORDO_AP',
                                               NULL,
                                               p_carta_acordo_id,
                                               p_empresa_id) = 1);
     --
     IF v_qt > 0
     THEN
      v_retorno := 1;
     END IF;
    ELSE
     -- carta acordo com itens de B/C
     SELECT COUNT(*)
       INTO v_qt
       FROM faixa_aprov       fa,
            faixa_aprov_papel fp,
            faixa_aprov_ao    fo
      WHERE fa.empresa_id = p_empresa_id
        AND fa.tipo_faixa = 'AO'
        AND fa.flag_ativo = 'S'
        AND fa.faixa_aprov_id = fo.faixa_aprov_id
        AND fo.flag_itens_bc = 'S'
        AND v_valor_aprovado BETWEEN fo.valor_de AND nvl(fo.valor_ate, 99999999999999999999)
        AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
        AND (fo.fornec_homolog = 'A' OR fo.fornec_homolog = v_flag_fornec_homolog)
        AND (fo.fornec_interno = 'A' OR fo.fornec_interno = v_flag_fornec_interno)
        AND fa.faixa_aprov_id = fp.faixa_aprov_id
        AND EXISTS (SELECT 1
               FROM usuario_papel up,
                    usuario       us
              WHERE up.papel_id = fp.papel_id
                AND up.usuario_id = us.usuario_id
                AND us.flag_admin = 'N'
                AND us.flag_ativo = 'S'
                AND usuario_pkg.priv_verificar(us.usuario_id,
                                               'CARTA_ACORDO_AP',
                                               NULL,
                                               p_carta_acordo_id,
                                               p_empresa_id) = 1);
     --
     IF v_qt > 0
     THEN
      v_retorno := 1;
     END IF;
    END IF; -- fim do IF v_tipo_item
   END IF; -- fim do IF v_valor_aprovado
  END IF; -- fim do IF v_aprova_faixa
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END usuario_aprov_verificar;
 --
 --
 FUNCTION papel_priv_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/10/2016
  -- DESCRICAO: verifica se o usuario possui esse papel e se esse papel lhe da o privilegio
  --  indicado nessa AO .
  --
  --  Retorna '1' caso o usuario possua o privilegio ou '0', caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia). Remocao do
  --                               parametro USAR_PRIV_PAPEL_ENDER.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo_priv       IN privilegio.codigo%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER AS
 
  v_ret         INTEGER;
  v_qt          INTEGER;
  v_flag_admin  usuario.flag_admin%TYPE;
  v_flag_ativo  usuario.flag_ativo%TYPE;
  v_abrangencia papel_priv.abrangencia%TYPE;
  v_empresa_id  papel.empresa_id%TYPE;
  --
 BEGIN
  v_ret := 0;
  --
  -- verifica o tipo de usuario
  SELECT flag_admin,
         flag_ativo
    INTO v_flag_admin,
         v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- usuario administrador pode tudo.
  IF v_flag_admin = 'S'
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -- usuario inativo nao tem privilegio.
  IF v_flag_ativo = 'N'
  THEN
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  SELECT empresa_id
    INTO v_empresa_id
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  -----------------------------------------------------------
  -- verifica se o papel do usuario garante privilegio
  -- para realizar a operacao.
  -----------------------------------------------------------
  SELECT COUNT(*),
         to_char(MAX(pp.abrangencia))
    INTO v_qt,
         v_abrangencia
    FROM usuario_papel up,
         papel_priv    pp,
         privilegio    pr,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = v_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = p_codigo_priv
     AND pa.papel_id = p_papel_id;
  --
  IF v_qt = 0
  THEN
   -- usuario nao tem privilegio
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- usuario tem privilegio sobre qualquer objeto, sem
  -- necessidade de se verificar enderecamento
  -----------------------------------------------------------
  IF v_abrangencia = 'T'
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- verificacao de enderecamento em algum job da carta
  -----------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario ju,
         item_carta  ic,
         item        it
   WHERE ju.usuario_id = p_usuario_sessao_id
     AND ju.job_id = it.job_id
     AND it.item_id = ic.item_id
     AND ic.carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt > 0
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- verificacao de enderecamento em alguma estim da carta
  -----------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_usuario ou,
         item_carta    ic,
         item          it
   WHERE ou.usuario_id = p_usuario_sessao_id
     AND ou.orcamento_id = it.orcamento_id
     AND ou.atuacao = 'ENDER'
     AND it.item_id = ic.item_id
     AND ic.carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt > 0
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN OTHERS THEN
   v_ret := 0;
   RETURN v_ret;
 END papel_priv_verificar;
 --
--
END; -- CARTA_ACORDO_PKG

/
