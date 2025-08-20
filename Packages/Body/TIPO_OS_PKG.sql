--------------------------------------------------------
--  DDL for Package Body TIPO_OS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_OS_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 20/07/2012
  -- DESCRICAO: Inclusão de TIPO_OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2014  Inclusao de configuracoes de eventos/notificacoes.
  -- Silvia            25/09/2018  Novo parametro cor_no_quadro
  -- Silvia            06/12/2018  Consistencia do codigo.
  -- Silvia            25/09/2019  Troca do nome de OS para Workflow.
  -- Silvia            01/09/2022  Novo atributo TIPO_TELA_NOVA_OS
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_codigo            IN tipo_os.codigo%TYPE,
  p_nome              IN tipo_os.nome%TYPE,
  p_ordem             IN VARCHAR2,
  p_cor_no_quadro     IN VARCHAR2,
  p_tipo_os_id        OUT tipo_os.tipo_os_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_ordem          tipo_os.ordem%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt         := 0;
  p_tipo_os_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(TRIM(p_codigo), ' ') > 0 OR instr(TRIM(p_codigo), '%') > 0 OR
     lower(TRIM(p_codigo)) <> acento_retirar(TRIM(p_codigo)) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código não pode ter caracteres em branco, com acentuação ou % (' ||
                 upper(p_codigo) || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  --
  IF TRIM(p_cor_no_quadro) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da cor do cartão no quadro é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cor_no_quadro) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A cor do cartão no quadro não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE upper(nome) = upper(TRIM(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_os.nextval
    INTO v_tipo_os_id
    FROM dual;
  --
  INSERT INTO tipo_os
   (tipo_os_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    cor_no_quadro,
    flag_ativo,
    tipo_termino_exec,
    tipo_tela_nova_os)
  VALUES
   (v_tipo_os_id,
    p_empresa_id,
    upper(TRIM(p_codigo)),
    TRIM(p_nome),
    v_ordem,
    TRIM(p_cor_no_quadro),
    'S',
    'UNI',
    'COMPLETA');
  --
  INSERT INTO tipo_os_transicao
   (tipo_os_id,
    os_transicao_id)
   SELECT v_tipo_os_id,
          os_transicao_id
     FROM os_transicao
    WHERE workflow = 'PADRAO'
       OR workflow LIKE 'COM_%';
  --
  -- cria registros de configuracao de notificacoes (eventos)
  evento_pkg.carregar;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_os_pkg.xml_gerar(v_tipo_os_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo)) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_os_id,
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
  p_tipo_os_id := v_tipo_os_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 25/05/2010
  -- DESCRICAO: Atualização de TIPO_OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/07/2012  Novos atributos: modelo_itens, ordem.
  -- Silvia            30/07/2014  Novos flags de parametros de workflow (aprovacao)
  -- Silvia            10/10/2014  Novos parametros p/ arquivos de aprovacao
  -- Silvia            28/10/2014  Novo parametro p_flag_pode_pular_aval
  -- Silvia            18/11/2014  Novo flag imprimir historico.
  -- Silvia            02/12/2014  Novo parametro flag_tem_meta_item
  -- Silvia            12/03/2015  Novo parametro flag_obriga_tam
  -- Silvia            22/05/2015  Novos parametros flag_acei_todas, flag_solic_v_emaval
  -- Silvia            10/09/2015  Novos parametros p/ configurar esquema/modo de distrib.
  -- Silvia            08/12/2015  Novo parametro flag_tem_estim
  -- Silvia            08/03/2016  Novo parametro flag_faixa_aprov
  -- Silvia            20/04/2016  Novos atributos p/ configurar estimativa e obrigar apont.
  -- Silvia            25/04/2016  Novo: flag_obriga_apont_exec; remocao: flag_tem_agenda
  -- Silvia            29/03/2017  Novo: flag_estim_obs
  -- Silvia            29/06/2017  Novos parametros p/ arquivos de refacao
  -- Silvia            29/03/2018  Novo parametro flag_exec_estim
  -- Silvia            24/07/2018  Removido: media_pontos; Novo: flag_calc_prazo_tam
  -- Silvia            25/09/2018  Novo parametro cor_no_quadro
  -- Silvia            06/12/2018  Consistencia do codigo.
  -- Silvia            19/02/2019  Novo parametro flag_solic_pode_encam
  -- Silvia            19/05/2020  Eliminacao de flag_estim_horas_papel
  -- Silvia            17/02/2021  Novos parametros acoes e num_dias_conc_os
  -- Silvia            26/05/2021  Novos paramentos: flag_pode_anexar_arqex,
  --                               flag_obriga_anexar_arqex
  -- Silvia            15/07/2021  Novo parametro num_max_itens
  -- Silvia            24/08/2021  Novo parametro flag_pode_refazer.
  -- Silvia            05/10/2021  Novo parametro flag_tem_qtd_item
  -- Silvia            18/11/2021  Alteracao de modelo_itens p/ 4000 caracteres
  -- Silvia            24/02/2022  Alteracao de modelo_itens p/ CLOB caracteres
  -- Siliva            24/03/2022  Novos parametros: flag_depende_out,
  --                               flag_pode_aval_solic, flag_pode_aval_exec
  -- Silvia            10/06/2022  Novo parametro: flag_pode_refaz_em_novo
  -- Silvia            16/08/2022  Novo parametro flag_apont_horas_aloc
  -- Silvia            18/08/2022  Drop nas colunas relacionadas a modo de distribuicao
  -- Silvia            01/09/2022  Novo atributo TIPO_TELA_NOVA_OS
  -- Ana Luiza         13/12/2024  Nova atributo flag_tem_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_tipo_os_id                IN tipo_os.tipo_os_id%TYPE,
  p_nome                      IN tipo_os.nome%TYPE,
  p_codigo                    IN tipo_os.codigo%TYPE,
  p_ordem                     IN VARCHAR2,
  p_cor_no_quadro             IN VARCHAR2,
  p_flag_ativo                IN VARCHAR2,
  p_tipo_tela_nova_os         IN VARCHAR2,
  p_flag_tem_tipo_finan       IN VARCHAR2,
  p_flag_tem_produto          IN VARCHAR2,
  p_flag_obriga_apont_exec    IN VARCHAR2,
  p_flag_depende_out          IN VARCHAR2,
  p_flag_tem_estim            IN VARCHAR2,
  p_flag_estim_horas_usu      IN VARCHAR2,
  p_flag_estim_prazo          IN VARCHAR2,
  p_flag_estim_custo          IN VARCHAR2,
  p_flag_estim_arq            IN VARCHAR2,
  p_flag_estim_obs            IN VARCHAR2,
  p_flag_exec_estim           IN VARCHAR2,
  p_flag_tem_descricao        IN VARCHAR2,
  p_flag_impr_briefing        IN VARCHAR2,
  p_flag_impr_prazo_estim     IN VARCHAR2,
  p_flag_impr_historico       IN VARCHAR2,
  p_flag_item_existente       IN VARCHAR2,
  p_flag_pode_refazer         IN VARCHAR2,
  p_flag_pode_refaz_em_novo   IN VARCHAR2,
  p_flag_pode_aval_solic      IN VARCHAR2,
  p_flag_pode_aval_exec       IN VARCHAR2,
  p_flag_tem_corpo            IN VARCHAR2,
  p_flag_tem_itens            IN VARCHAR2,
  p_flag_tem_qtd_item         IN VARCHAR2,
  p_flag_tem_desc_item        IN VARCHAR2,
  p_flag_tem_meta_item        IN VARCHAR2,
  p_flag_tem_importacao       IN VARCHAR2,
  p_num_max_itens             IN VARCHAR2,
  p_flag_solic_alt_arqref     IN VARCHAR2,
  p_flag_exec_alt_arqexe      IN VARCHAR2,
  p_tipo_termino_exec         IN VARCHAR2,
  p_modelo                    IN tipo_os.modelo%TYPE,
  p_modelo_itens              IN tipo_os.modelo_itens%TYPE,
  p_flag_tem_pontos_tam       IN VARCHAR2,
  p_flag_calc_prazo_tam       IN VARCHAR2,
  p_flag_obriga_tam           IN VARCHAR2,
  p_pontos_tam_p              IN VARCHAR2,
  p_pontos_tam_m              IN VARCHAR2,
  p_pontos_tam_g              IN VARCHAR2,
  p_flag_apont_horas_aloc     IN VARCHAR2,
  p_vetor_workflow            IN VARCHAR2,
  p_status_integracao         IN VARCHAR2,
  p_cod_ext_tipo_os           IN VARCHAR2,
  p_tam_max_arq_ref           IN VARCHAR2,
  p_qtd_max_arq_ref           IN VARCHAR2,
  p_extensoes_ref             IN VARCHAR2,
  p_tam_max_arq_exe           IN VARCHAR2,
  p_qtd_max_arq_exe           IN VARCHAR2,
  p_extensoes_exe             IN VARCHAR2,
  p_tam_max_arq_apr           IN VARCHAR2,
  p_qtd_max_arq_apr           IN VARCHAR2,
  p_extensoes_apr             IN VARCHAR2,
  p_flag_pode_anexar_arqapr   IN VARCHAR2,
  p_tam_max_arq_est           IN VARCHAR2,
  p_qtd_max_arq_est           IN VARCHAR2,
  p_extensoes_est             IN VARCHAR2,
  p_tam_max_arq_rfa           IN VARCHAR2,
  p_qtd_max_arq_rfa           IN VARCHAR2,
  p_extensoes_rfa             IN VARCHAR2,
  p_flag_pode_pular_aval      IN VARCHAR2,
  p_flag_pode_anexar_arqexe   IN VARCHAR2,
  p_flag_obriga_anexar_arqexe IN VARCHAR2,
  p_flag_aprov_refaz          IN VARCHAR2,
  p_flag_aprov_devolve        IN VARCHAR2,
  p_flag_habilita_aprov       IN VARCHAR2,
  p_flag_acei_todas           IN VARCHAR2,
  p_flag_solic_v_emaval       IN VARCHAR2,
  p_flag_faixa_aprov          IN VARCHAR2,
  p_flag_solic_pode_encam     IN VARCHAR2,
  p_flag_dist_com_ender       IN VARCHAR2,
  p_acoes_executadas          IN VARCHAR2,
  p_acoes_depois              IN VARCHAR2,
  p_num_dias_conc_os          IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_codigo_old       tipo_os.codigo%TYPE;
  v_ordem            tipo_os.ordem%TYPE;
  v_pontos_tam_p     tipo_os.pontos_tam_p%TYPE;
  v_pontos_tam_m     tipo_os.pontos_tam_m%TYPE;
  v_pontos_tam_g     tipo_os.pontos_tam_g%TYPE;
  v_tam_max_arq_ref  tipo_os.tam_max_arq_ref%TYPE;
  v_qtd_max_arq_ref  tipo_os.qtd_max_arq_ref%TYPE;
  v_extensoes_ref    tipo_os.extensoes_ref%TYPE;
  v_tam_max_arq_exe  tipo_os.tam_max_arq_exe%TYPE;
  v_qtd_max_arq_exe  tipo_os.qtd_max_arq_exe%TYPE;
  v_extensoes_exe    tipo_os.extensoes_exe%TYPE;
  v_tam_max_arq_apr  tipo_os.tam_max_arq_apr%TYPE;
  v_qtd_max_arq_apr  tipo_os.qtd_max_arq_apr%TYPE;
  v_extensoes_apr    tipo_os.extensoes_apr%TYPE;
  v_tam_max_arq_est  tipo_os.tam_max_arq_est%TYPE;
  v_qtd_max_arq_est  tipo_os.qtd_max_arq_est%TYPE;
  v_extensoes_est    tipo_os.extensoes_est%TYPE;
  v_tam_max_arq_rfa  tipo_os.tam_max_arq_rfa%TYPE;
  v_qtd_max_arq_rfa  tipo_os.qtd_max_arq_rfa%TYPE;
  v_extensoes_rfa    tipo_os.extensoes_rfa%TYPE;
  v_num_dias_conc_os tipo_os.num_dias_conc_os%TYPE;
  v_num_max_itens    tipo_os.num_max_itens%TYPE;
  v_vetor_workflow   VARCHAR2(1000);
  v_workflow         os_transicao.workflow%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT TRIM(upper(codigo))
    INTO v_codigo_old
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(TRIM(p_codigo), ' ') > 0 OR instr(TRIM(p_codigo), '%') > 0 OR
     lower(TRIM(p_codigo)) <> acento_retirar(TRIM(p_codigo)) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código não pode ter caracteres em branco, com acentuação ou % (' ||
                 upper(p_codigo) || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  --
  IF TRIM(p_cor_no_quadro) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da cor do cartão no quadro é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cor_no_quadro) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A cor do cartão no quadro não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_descricao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem descrição inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_tipo_finan) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem tipo financeiro inválido.';
   RAISE v_exception;
  END IF;
  --ALCBO_131224
  IF flag_validar(p_flag_tem_produto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem produto inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_item_existente) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite itens existentes inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_refazer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite solicitar refação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_refaz_em_novo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode refazer em novo workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_aval_solic) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite avaliar solicitação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_aval_exec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite avaliar execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_apont_exec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga apontamento na execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_depende_out) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag depende de outros workflows inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_faixa_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem configuração de aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  -- integrar ao entrar no status
  IF TRIM(p_status_integracao) IS NOT NULL AND
     util_pkg.desc_retornar('status_os', p_status_integracao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status para integração inválido (' || p_status_integracao || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_ext_tipo_os) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código no sistema externo não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_tipo_os || ').';
   RAISE v_exception;
  END IF;
  --
  -- estimativa da OS
  IF flag_validar(p_flag_tem_estim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim_horas_usu) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag estimar horas por usuário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag estimar prazo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim_custo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag estimar custo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim_arq) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag anexar arquivo de estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim_obs) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag observação na estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_exec_estim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar estimativa na execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tem_estim = 'S' AND p_flag_estim_horas_usu = 'N' AND p_flag_estim_prazo = 'N' AND
     p_flag_estim_custo = 'N' AND p_flag_estim_arq = 'N' AND p_flag_estim_obs = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para permitir a iteração de estimativa, ' ||
                 'pelo menos uma modalidade deve estar habilitada.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tem_estim = 'N' AND
     (p_flag_estim_horas_usu = 'S' OR p_flag_estim_prazo = 'S' OR p_flag_estim_custo = 'S' OR
     p_flag_estim_arq = 'S' OR p_flag_estim_obs = 'S') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma modalidade de estimativa está habilitada porém a ' ||
                 'permissão da iteração não foi selecionada.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_tela_nova_os) IS NULL OR p_tipo_tela_nova_os NOT IN ('COMPLETA', 'SIMPLES') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de tela na criação de novo Workflow inválido (' || p_tipo_tela_nova_os || ').';
   RAISE v_exception;
  END IF;
  --
  -- corpo da OS
  IF flag_validar(p_flag_tem_corpo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem corpo inválido.';
   RAISE v_exception;
  END IF;
  --
  -- itens de OS
  IF flag_validar(p_flag_tem_itens) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem itens inválido.';
   RAISE v_exception;
  END IF;
  --
  -- itens de OS
  IF flag_validar(p_flag_tem_qtd_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem quantidade do item inválido.';
   RAISE v_exception;
  END IF;
  --
  -- intens de OS
  IF flag_validar(p_flag_tem_desc_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem descrição do item inválido.';
   RAISE v_exception;
  END IF;
  --
  -- itens de OS
  IF flag_validar(p_flag_tem_meta_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem metadados no item inválido.';
   RAISE v_exception;
  END IF;
  --
  -- itens de OS
  IF flag_validar(p_flag_tem_importacao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem importação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_max_itens) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_max_itens := to_number(p_num_max_itens);
  --
  IF v_num_max_itens <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_anexar_arqapr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode anexar arquivo de aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  -- itens de OS
  -- impressao
  IF flag_validar(p_flag_impr_briefing) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag imprime briefing inválido.';
   RAISE v_exception;
  END IF;
  --
  -- impressao
  IF flag_validar(p_flag_impr_prazo_estim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag imprime prazo estimado inválido.';
   RAISE v_exception;
  END IF;
  --
  -- impressao
  IF flag_validar(p_flag_impr_historico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag imprime histórico inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na aceitacao sem distribuicao
  IF flag_validar(p_flag_acei_todas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag na aceitação sem distrinuição inválido.';
   RAISE v_exception;
  END IF;
  --
  -- no termino da execucao
  IF TRIM(p_tipo_termino_exec) IS NULL OR p_tipo_termino_exec NOT IN ('UNI', 'IND') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de término da execução inválido (' || p_tipo_termino_exec || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_termino_exec) = 'UNI' AND p_flag_pode_aval_solic = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A avaliação da solicitação pelos executores não pode ser ' ||
                 'ativada em conjunto com o término da execução por um único usuário.';
   RAISE v_exception;
  END IF;
  --
  -- na aprovacao
  IF flag_validar(p_flag_pode_pular_aval) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode pular avaliação inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na aprovacao
  IF flag_validar(p_flag_solic_v_emaval) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag solicitante pode ver em avaliação inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na aprovacao do cliente
  IF flag_validar(p_flag_aprov_refaz) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovador comanda refação inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na aprovacao do cliente
  IF flag_validar(p_flag_aprov_devolve) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovador devolve inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na aprovacao ou aprovacao do cliente
  IF flag_validar(p_flag_habilita_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar aprovar inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na anexacao de arquivos
  IF flag_validar(p_flag_solic_alt_arqref) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag solicitante altera arquivo de referência inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na anexacao de arquivos
  IF flag_validar(p_flag_exec_alt_arqexe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag executor altera arquivo de execução inválido.';
   RAISE v_exception;
  END IF;
  --
  -- na anexacao de arquivos de execucao
  IF flag_validar(p_flag_pode_anexar_arqexe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode anexar arquivos ou links de execução em Workflows em avaliação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_anexar_arqexe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga anexar arquivos ou links de execução em Workflows em execução.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE upper(nome) = upper(TRIM(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_os_id <> p_tipo_os_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  -- arquivos de referencia
  IF inteiro_validar(p_tam_max_arq_ref) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq_ref || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq_ref) = 0 OR to_number(p_qtd_max_arq_ref) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq_ref || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes_ref) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões de arquivos não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  -- arquivos de execucao
  IF inteiro_validar(p_tam_max_arq_exe) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq_exe || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq_exe) = 0 OR to_number(p_qtd_max_arq_exe) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq_exe || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes_exe) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões de arquivos não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  -- arquivos de aprovacao
  IF inteiro_validar(p_tam_max_arq_apr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq_apr || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq_apr) = 0 OR to_number(p_qtd_max_arq_apr) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq_apr || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes_apr) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões de arquivos não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  -- arquivos de estimativa
  IF inteiro_validar(p_tam_max_arq_est) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq_est || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq_est) = 0 OR to_number(p_qtd_max_arq_est) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq_est || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes_est) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões de arquivos não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  -- arquivos de refacao
  IF inteiro_validar(p_tam_max_arq_rfa) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq_rfa || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq_rfa) = 0 OR to_number(p_qtd_max_arq_rfa) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq_rfa || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes_rfa) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões de arquivos não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  v_tam_max_arq_ref := to_number(p_tam_max_arq_ref);
  v_qtd_max_arq_ref := to_number(p_qtd_max_arq_ref);
  v_extensoes_ref   := TRIM(REPLACE(p_extensoes_ref, ' ', ''));
  --
  v_tam_max_arq_exe := to_number(p_tam_max_arq_exe);
  v_qtd_max_arq_exe := to_number(p_qtd_max_arq_exe);
  v_extensoes_exe   := TRIM(REPLACE(p_extensoes_exe, ' ', ''));
  --
  v_tam_max_arq_apr := to_number(p_tam_max_arq_apr);
  v_qtd_max_arq_apr := to_number(p_qtd_max_arq_apr);
  v_extensoes_apr   := TRIM(REPLACE(p_extensoes_apr, ' ', ''));
  --
  v_tam_max_arq_est := to_number(p_tam_max_arq_est);
  v_qtd_max_arq_est := to_number(p_qtd_max_arq_est);
  v_extensoes_est   := TRIM(REPLACE(p_extensoes_est, ' ', ''));
  --
  v_tam_max_arq_rfa := to_number(p_tam_max_arq_rfa);
  v_qtd_max_arq_rfa := to_number(p_qtd_max_arq_rfa);
  v_extensoes_rfa   := TRIM(REPLACE(p_extensoes_rfa, ' ', ''));
  --
  -- estimativa de horas por tamanho
  IF flag_validar(p_flag_tem_pontos_tam) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem tamanho inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_calc_prazo_tam) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag calcular prazo pelo tamanho inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_tam) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga tamanho inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_calc_prazo_tam = 'S' AND p_flag_tem_pontos_tam = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Só é possível calcular o prazo em função do tamanho em Workflows que usam tamanho.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_obriga_tam = 'S' AND p_flag_tem_pontos_tam = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Só é possível obrigar a indicação do tamanho em Workflows que usam tamanho.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_calc_prazo_tam = 'S' AND
     (TRIM(p_pontos_tam_p) IS NULL OR TRIM(p_pontos_tam_m) IS NULL OR TRIM(p_pontos_tam_g) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das horas estimadas em função do tamanho é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_pontos_tam_p) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas estimadas para o tamanho P inválido (' || p_pontos_tam_p || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_pontos_tam_m) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas estimadas para o tamanho M inválido (' || p_pontos_tam_m || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_pontos_tam_g) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas estimadas para o tamanho G inválido (' || p_pontos_tam_g || ').';
   RAISE v_exception;
  END IF;
  --
  v_pontos_tam_p := to_number(p_pontos_tam_p);
  v_pontos_tam_m := to_number(p_pontos_tam_m);
  v_pontos_tam_g := to_number(p_pontos_tam_g);
  --
  IF flag_validar(p_flag_apont_horas_aloc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag apontar horas alocadas de forma automática inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_solic_pode_encam) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag solicitante pode encaminhar inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_dist_com_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag distribuição com endereçamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_acoes_executadas)) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As "ações executadas" não podem ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_acoes_depois)) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As "ações executadas depois" não podem ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_dias_conc_os) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias para conclusão automática inválido (' || p_num_dias_conc_os || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_conc_os := nvl(to_number(p_num_dias_conc_os), 0);
  --
  IF v_num_dias_conc_os < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias para conclusão automática inválido (' || p_num_dias_conc_os || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de workflow
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  DELETE FROM tipo_os_transicao
   WHERE tipo_os_id = p_tipo_os_id;
  --
  INSERT INTO tipo_os_transicao
   (tipo_os_id,
    os_transicao_id)
   SELECT p_tipo_os_id,
          os_transicao_id
     FROM os_transicao
    WHERE workflow = 'PADRAO';
  --
  v_vetor_workflow := p_vetor_workflow;
  --
  WHILE nvl(length(rtrim(v_vetor_workflow)), 0) > 0
  LOOP
   v_workflow := prox_valor_retornar(v_vetor_workflow, v_delimitador);
   --
   INSERT INTO tipo_os_transicao
    (tipo_os_id,
     os_transicao_id)
    SELECT p_tipo_os_id,
           os_transicao_id
      FROM os_transicao
     WHERE workflow = v_workflow;
  END LOOP;
  --
  SELECT COUNT(DISTINCT ot.workflow)
    INTO v_qt
    FROM tipo_os_transicao ti,
         os_transicao      ot
   WHERE ti.tipo_os_id = p_tipo_os_id
     AND ti.os_transicao_id = ot.os_transicao_id
     AND ot.workflow IN ('SEM_DIST', 'SEM_ACEI');
  --
  IF v_qt > 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Workflow não pode ficar sem distribuição e sem aceitação ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_os_pkg.xml_gerar(p_tipo_os_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_os
     SET nome                      = TRIM(p_nome),
         codigo                    = TRIM(upper(p_codigo)),
         modelo                    = p_modelo,
         modelo_itens              = p_modelo_itens,
         ordem                     = v_ordem,
         cor_no_quadro             = TRIM(p_cor_no_quadro),
         pontos_tam_p              = v_pontos_tam_p,
         pontos_tam_m              = v_pontos_tam_m,
         pontos_tam_g              = v_pontos_tam_g,
         flag_apont_horas_aloc     = p_flag_apont_horas_aloc,
         flag_ativo                = p_flag_ativo,
         flag_tem_tipo_finan       = p_flag_tem_tipo_finan,
         flag_tem_produto          = p_flag_tem_produto,
         flag_tem_estim            = p_flag_tem_estim,
         flag_faixa_aprov          = p_flag_faixa_aprov,
         flag_tem_descricao        = p_flag_tem_descricao,
         flag_pode_anexar_arqapr   = p_flag_pode_anexar_arqapr,
         flag_impr_briefing        = p_flag_impr_briefing,
         flag_impr_prazo_estim     = p_flag_impr_prazo_estim,
         flag_impr_historico       = p_flag_impr_historico,
         flag_item_existente       = p_flag_item_existente,
         flag_pode_refazer         = p_flag_pode_refazer,
         flag_pode_refaz_em_novo   = p_flag_pode_refaz_em_novo,
         flag_pode_aval_solic      = p_flag_pode_aval_solic,
         flag_pode_aval_exec       = p_flag_pode_aval_exec,
         flag_tem_corpo            = p_flag_tem_corpo,
         flag_tem_itens            = p_flag_tem_itens,
         flag_tem_qtd_item         = p_flag_tem_qtd_item,
         flag_tem_desc_item        = p_flag_tem_desc_item,
         flag_tem_meta_item        = p_flag_tem_meta_item,
         flag_tem_importacao       = p_flag_tem_importacao,
         flag_pode_pular_aval      = p_flag_pode_pular_aval,
         flag_aprov_refaz          = p_flag_aprov_refaz,
         flag_aprov_devolve        = p_flag_aprov_devolve,
         flag_habilita_aprov       = p_flag_habilita_aprov,
         flag_solic_alt_arqref     = p_flag_solic_alt_arqref,
         flag_exec_alt_arqexe      = p_flag_exec_alt_arqexe,
         flag_tem_pontos_tam       = p_flag_tem_pontos_tam,
         flag_calc_prazo_tam       = p_flag_calc_prazo_tam,
         flag_obriga_tam           = p_flag_obriga_tam,
         tipo_termino_exec         = TRIM(p_tipo_termino_exec),
         status_integracao         = TRIM(p_status_integracao),
         cod_ext_tipo_os           = TRIM(p_cod_ext_tipo_os),
         tam_max_arq_ref           = v_tam_max_arq_ref,
         qtd_max_arq_ref           = v_qtd_max_arq_ref,
         extensoes_ref             = v_extensoes_ref,
         tam_max_arq_exe           = v_tam_max_arq_exe,
         qtd_max_arq_exe           = v_qtd_max_arq_exe,
         extensoes_exe             = v_extensoes_exe,
         tam_max_arq_apr           = v_tam_max_arq_apr,
         qtd_max_arq_apr           = v_qtd_max_arq_apr,
         extensoes_apr             = v_extensoes_apr,
         tam_max_arq_est           = v_tam_max_arq_est,
         qtd_max_arq_est           = v_qtd_max_arq_est,
         extensoes_est             = v_extensoes_est,
         tam_max_arq_rfa           = v_tam_max_arq_rfa,
         qtd_max_arq_rfa           = v_qtd_max_arq_rfa,
         extensoes_rfa             = v_extensoes_rfa,
         flag_acei_todas           = p_flag_acei_todas,
         flag_solic_v_emaval       = p_flag_solic_v_emaval,
         flag_estim_horas_usu      = p_flag_estim_horas_usu,
         flag_estim_prazo          = p_flag_estim_prazo,
         flag_estim_custo          = p_flag_estim_custo,
         flag_estim_arq            = p_flag_estim_arq,
         flag_estim_obs            = p_flag_estim_obs,
         flag_exec_estim           = p_flag_exec_estim,
         flag_obriga_apont_exec    = p_flag_obriga_apont_exec,
         flag_depende_out          = p_flag_depende_out,
         flag_solic_pode_encam     = p_flag_solic_pode_encam,
         flag_dist_com_ender       = p_flag_dist_com_ender,
         acoes_executadas          = TRIM(p_acoes_executadas),
         acoes_depois              = TRIM(p_acoes_depois),
         num_dias_conc_os          = v_num_dias_conc_os,
         flag_pode_anexar_arqexe   = p_flag_pode_anexar_arqexe,
         flag_obriga_anexar_arqexe = p_flag_obriga_anexar_arqexe,
         num_max_itens             = v_num_max_itens,
         tipo_tela_nova_os         = TRIM(p_tipo_tela_nova_os)
   WHERE tipo_os_id = p_tipo_os_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_os_pkg.xml_gerar(p_tipo_os_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo)) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_os_id,
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 20/07/2012
  -- DESCRICAO: Exclusão de TIPO_OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2014  Exclusao de configuracoes de eventos/notificacoes.
  -- Silvia            03/03/2020  Eliminacao de painel
  -- Joel Dias         14/06/2024  Inclusão da exclusão do tipo de OS de Quadros
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN tipo_os.tipo_os_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_nome           tipo_os.nome%TYPE;
  v_codigo         tipo_os.codigo%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE tipo_os_id = p_tipo_os_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem Workflows que usam esse tipo.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_painel_tos
     WHERE tipo_os_id = p_tipo_os_id
       AND ROWNUM = 1;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Existem papéis configurados com dashboards para esse tipo de Workflow.';
       RAISE v_exception;
    END IF;
  --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_priv_tos
     WHERE tipo_os_id = p_tipo_os_id
       AND ROWNUM = 1;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Existem papéis configurados com privilégios para esse tipo de Workflow.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_os_pkg.xml_gerar(p_tipo_os_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM metadado
   WHERE objeto_id = p_tipo_os_id
     AND tipo_objeto = 'TIPO_OS'
     AND empresa_id = p_empresa_id;
  DELETE FROM tipo_prod_tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  DELETE FROM tipo_os_transicao
   WHERE tipo_os_id = p_tipo_os_id;
  DELETE FROM evento_motivo
   WHERE tipo_os_id = p_tipo_os_id;
  --
  DELETE FROM notifica_usuario nt
   WHERE EXISTS (SELECT 1
            FROM notifica_config nc,
                 evento_config   ec
           WHERE nc.notifica_config_id = nt.notifica_config_id
             AND nc.evento_config_id = ec.evento_config_id
             AND ec.tipo_os_id = p_tipo_os_id);
  --
  DELETE FROM notifica_papel nt
   WHERE EXISTS (SELECT 1
            FROM notifica_config nc,
                 evento_config   ec
           WHERE nc.notifica_config_id = nt.notifica_config_id
             AND nc.evento_config_id = ec.evento_config_id
             AND ec.tipo_os_id = p_tipo_os_id);
  --
  DELETE FROM notifica_config nc
   WHERE EXISTS (SELECT 1
            FROM evento_config ec
           WHERE nc.evento_config_id = ec.evento_config_id
             AND ec.tipo_os_id = p_tipo_os_id);
  --
  DELETE FROM papel_priv_tos
   WHERE tipo_os_id = p_tipo_os_id;
  --
  DELETE FROM evento_config
   WHERE tipo_os_id = p_tipo_os_id;
  --
  DELETE FROM quadro_os_config
   WHERE tipo_os_id = p_tipo_os_id;
  --
  DELETE FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;

  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo || ' - ' || v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_os_id,
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
 PROCEDURE privilegio_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/01/2013
  -- DESCRICAO: Inclusão de privilégio para um determinado TIPO_OS x Papel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN papel_priv_tos.tipo_os_id%TYPE,
  p_papel_id          IN papel_priv_tos.papel_id%TYPE,
  p_privilegio_id     IN papel_priv_tos.privilegio_id%TYPE,
  p_abrangencia       IN papel_priv_tos.abrangencia%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_tos_nome       tipo_os.nome%TYPE;
  v_tos_codigo     tipo_os.codigo%TYPE;
  v_papel_nome     papel.nome%TYPE;
  v_priv_nome      privilegio.nome%TYPE;
  v_ender          VARCHAR2(100);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM privilegio
   WHERE privilegio_id = p_privilegio_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse privilégio não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_abrangencia) IS NULL OR p_abrangencia NOT IN ('T', 'P') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Abrangência inválida (' || p_abrangencia || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_papel_nome
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  SELECT nome
    INTO v_priv_nome
    FROM privilegio
   WHERE privilegio_id = p_privilegio_id;
  --
  SELECT codigo,
         nome
    INTO v_tos_codigo,
         v_tos_nome
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  IF p_abrangencia = 'T' THEN
   v_ender := 'qualquer usuário';
  ELSE
   v_ender := 'usuários endereçados';
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv_tos
   WHERE tipo_os_id = p_tipo_os_id
     AND papel_id = p_papel_id
     AND privilegio_id = p_privilegio_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse privilégio/papel já está associado a esse tipo de Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv
   WHERE papel_id = p_papel_id
     AND privilegio_id = p_privilegio_id;
  --
  IF v_qt = 0 THEN
   INSERT INTO papel_priv
    (papel_id,
     privilegio_id,
     abrangencia)
   VALUES
    (p_papel_id,
     p_privilegio_id,
     'P');
  END IF;
  --
  INSERT INTO papel_priv_tos
   (papel_id,
    privilegio_id,
    tipo_os_id,
    abrangencia)
  VALUES
   (p_papel_id,
    p_privilegio_id,
    p_tipo_os_id,
    p_abrangencia);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_tos_codigo || ' - ' || v_tos_nome;
  v_compl_histor   := 'Inclusão de privilégio/papel: ' || v_priv_nome || '; ' || v_papel_nome || '; ' ||
                      v_ender;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_os_id,
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
 END privilegio_adicionar;
 --
 --
 PROCEDURE privilegio_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/01/2013
  -- DESCRICAO: Exclusão de privilégio de um determinado TIPO_OS x Papel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN papel_priv_tos.tipo_os_id%TYPE,
  p_papel_id          IN papel_priv_tos.papel_id%TYPE,
  p_privilegio_id     IN papel_priv_tos.privilegio_id%TYPE,
  p_abrangencia       IN papel_priv_tos.abrangencia%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_tos_nome       tipo_os.nome%TYPE;
  v_tos_codigo     tipo_os.codigo%TYPE;
  v_papel_nome     papel.nome%TYPE;
  v_priv_nome      privilegio.nome%TYPE;
  v_ender          VARCHAR2(100);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM privilegio
   WHERE privilegio_id = p_privilegio_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse privilégio não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_abrangencia) IS NULL OR p_abrangencia NOT IN ('T', 'P') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Abrangência inválida (' || p_abrangencia || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_papel_nome
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  SELECT nome
    INTO v_priv_nome
    FROM privilegio
   WHERE privilegio_id = p_privilegio_id;
  --
  SELECT codigo,
         nome
    INTO v_tos_codigo,
         v_tos_nome
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  IF p_abrangencia = 'T' THEN
   v_ender := 'qualquer usuário';
  ELSE
   v_ender := 'usuários endereçados';
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv_tos
   WHERE tipo_os_id = p_tipo_os_id
     AND papel_id = p_papel_id
     AND privilegio_id = p_privilegio_id
     AND abrangencia = p_abrangencia;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse privilégio/papel não está associado a esse tipo de Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_priv_tos
   WHERE tipo_os_id = p_tipo_os_id
     AND papel_id = p_papel_id
     AND privilegio_id = p_privilegio_id;
  --
  DELETE FROM papel_priv pp
   WHERE papel_id = p_papel_id
     AND privilegio_id = p_privilegio_id
     AND NOT EXISTS (SELECT 1
            FROM papel_priv_tos pt
           WHERE pp.papel_id = pt.papel_id);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_tos_codigo || ' - ' || v_tos_nome;
  v_compl_histor   := 'Exclusão de privilégio/papel: ' || v_priv_nome || '; ' || v_papel_nome || '; ' ||
                      v_ender;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_os_id,
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
 END privilegio_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/01/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de OS para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_os_id IN tipo_os.tipo_os_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_ot IS
   SELECT ot.status_de,
          ot.status_para,
          ot.cod_acao
     FROM tipo_os_transicao tt,
          os_transicao      ot
    WHERE tt.tipo_os_id = p_tipo_os_id
      AND tt.os_transicao_id = ot.os_transicao_id
    ORDER BY ot.status_de,
             ot.status_para;
  --
  CURSOR c_to IS
   SELECT pr.nome,
          pr.codigo,
          pa.nome AS papel,
          decode(pt.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang_sec
     FROM privilegio     pr,
          papel_priv_tos pt,
          papel          pa
    WHERE pt.tipo_os_id = p_tipo_os_id
      AND pt.privilegio_id = pr.privilegio_id
      AND pt.papel_id = pa.papel_id
    ORDER BY pr.nome,
             pt.abrangencia,
             pa.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tipo_os_id", ti.tipo_os_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("tem_nome", ti.flag_tem_descricao),
                   xmlelement("tem_tipo_finan", ti.flag_tem_tipo_finan),
                   xmlelement("permite_item_existente", ti.flag_item_existente),
                   xmlelement("usa_faixa_aprov", ti.flag_faixa_aprov),
                   xmlelement("status_integracao", ti.status_integracao),
                   xmlelement("cod_ext_tipo_os", ti.cod_ext_tipo_os),
                   xmlelement("obriga_apont_na_exec", ti.flag_obriga_apont_exec),
                   xmlelement("depende_outros", ti.flag_depende_out),
                   xmlelement("tem_iteracao_estim", ti.flag_tem_estim),
                   xmlelement("estima_horas_usuario", ti.flag_estim_horas_usu),
                   xmlelement("estima_prazo", ti.flag_estim_prazo),
                   xmlelement("estima_custo", ti.flag_estim_custo),
                   xmlelement("tem_arquivo_estim", ti.flag_estim_arq),
                   xmlelement("tem_obs_estim", ti.flag_estim_obs),
                   xmlelement("tem_estim_na_exec", ti.flag_exec_estim),
                   xmlelement("tem_corpo", ti.flag_tem_corpo),
                   xmlelement("tem_itens", ti.flag_tem_itens),
                   xmlelement("itens_tem_quantidade", ti.flag_tem_qtd_item),
                   xmlelement("itens_tem_descricao", ti.flag_tem_desc_item),
                   xmlelement("itens_tem_metadados", ti.flag_tem_meta_item),
                   xmlelement("itens_tem_imp_exp", ti.flag_tem_importacao),
                   xmlelement("itens_num_max", ti.num_max_itens),
                   xmlelement("impr_com_briefing", ti.flag_impr_briefing),
                   xmlelement("impr_com_prazo", ti.flag_impr_prazo_estim),
                   xmlelement("impr_com_historico", ti.flag_impr_historico),
                   xmlelement("usa_tamanho", to_char(ti.flag_tem_pontos_tam)),
                   xmlelement("calcula_prazo_com_tamanho", to_char(ti.flag_calc_prazo_tam)),
                   xmlelement("obriga_tamanho", to_char(ti.flag_obriga_tam)),
                   xmlelement("pontos_tam_p", to_char(ti.pontos_tam_p)),
                   xmlelement("pontos_tam_m", to_char(ti.pontos_tam_m)),
                   xmlelement("pontos_tam_g", to_char(ti.pontos_tam_g)),
                   xmlelement("aponta_horas_alocadas", ti.flag_apont_horas_aloc),
                   xmlelement("pode_aceitar_qq_os", ti.flag_acei_todas),
                   xmlelement("pode_pular_aval", ti.flag_pode_pular_aval),
                   xmlelement("pode_refazer", ti.flag_pode_refazer),
                   xmlelement("pode_refazer_em_novo", ti.flag_pode_refaz_em_novo),
                   xmlelement("pode_avaliar_solic", ti.flag_pode_aval_solic),
                   xmlelement("pode_avaliar_exec", ti.flag_pode_aval_exec),
                   xmlelement("pode_anexar_arqexe", ti.flag_pode_anexar_arqexe),
                   xmlelement("obriga_anexar_arqexe", ti.flag_obriga_anexar_arqexe),
                   xmlelement("pode_ver_aval_inbox", ti.flag_solic_v_emaval),
                   xmlelement("pode_refazer_aprov_cli", ti.flag_aprov_refaz),
                   xmlelement("pode_devolver_aprov_cli", ti.flag_aprov_devolve),
                   xmlelement("habilita_aprov", ti.flag_habilita_aprov),
                   xmlelement("solicitante_alt_arq_ref", ti.flag_solic_alt_arqref),
                   xmlelement("executor_alt_arq_exe", ti.flag_exec_alt_arqexe),
                   xmlelement("cor_no_quadro", ti.cor_no_quadro),
                   xmlelement("num_dias_conc_autom", ti.num_dias_conc_os),
                   xmlelement("tipo_tela_nova_os", ti.tipo_tela_nova_os))
    INTO v_xml
    FROM tipo_os ti
   WHERE ti.tipo_os_id = p_tipo_os_id;
  --
  ------------------------------------------------------------
  -- monta as informacoes de arquivos
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  --
  SELECT xmlagg(xmlelement("arquivo_refer",
                           xmlelement("tam_max_arq", to_char(ti.tam_max_arq_ref)),
                           xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq_ref)),
                           xmlelement("extensoes", to_char(ti.extensoes_ref))))
    INTO v_xml_aux99
    FROM tipo_os ti
   WHERE ti.tipo_os_id = p_tipo_os_id;
  --
  SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlagg(xmlelement("arquivo_estim",
                           xmlelement("tam_max_arq", to_char(ti.tam_max_arq_est)),
                           xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq_est)),
                           xmlelement("extensoes", to_char(ti.extensoes_est))))
    INTO v_xml_aux99
    FROM tipo_os ti
   WHERE ti.tipo_os_id = p_tipo_os_id;
  --
  SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlagg(xmlelement("arquivo_exec",
                           xmlelement("tam_max_arq", to_char(ti.tam_max_arq_exe)),
                           xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq_exe)),
                           xmlelement("extensoes", to_char(ti.extensoes_exe))))
    INTO v_xml_aux99
    FROM tipo_os ti
   WHERE ti.tipo_os_id = p_tipo_os_id;
  --
  SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlagg(xmlelement("arquivo_aprov",
                           xmlelement("tam_max_arq", to_char(ti.tam_max_arq_apr)),
                           xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq_apr)),
                           xmlelement("extensoes", to_char(ti.extensoes_apr)),
                           xmlelement("pode_anexar", to_char(ti.flag_pode_anexar_arqapr))))
    INTO v_xml_aux99
    FROM tipo_os ti
   WHERE ti.tipo_os_id = p_tipo_os_id;
  --
  SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlagg(xmlelement("arquivos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta TRANSICOES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ot IN c_ot
  LOOP
   SELECT xmlagg(xmlelement("transicao",
                            xmlelement("status_de", r_ot.status_de),
                            xmlelement("status_para", r_ot.status_para),
                            xmlelement("cod_acao", r_ot.cod_acao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("transicoes", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO OS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_to IN c_to
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_to.codigo),
                            xmlelement("priv_nome", r_to.nome),
                            xmlelement("papel", r_to.papel),
                            xmlelement("abrang", r_to.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_tipo_os", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_os"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_os", v_xml))
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
 PROCEDURE duplicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind     DATA: 03/06/2024
  -- DESCRICAO: Duplicação de TIPO_OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- -                 99/99/9999  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_codigo              IN tipo_os.codigo%TYPE,
  p_nome                IN tipo_os.nome%TYPE,
  p_tipo_os_duplicar_id IN tipo_os.tipo_os_id%TYPE,
  p_tipo_os_id          OUT tipo_os.tipo_os_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_ordem          tipo_os.ordem%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt         := 0;
  p_tipo_os_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_OS_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF instr(TRIM(p_codigo), ' ') > 0 OR instr(TRIM(p_codigo), '%') > 0 OR
     lower(TRIM(p_codigo)) <> acento_retirar(TRIM(p_codigo)) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código não pode ter caracteres em branco, com acentuação ou % (' ||
                 upper(p_codigo) || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE upper(nome) = upper(TRIM(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_os.nextval
    INTO v_tipo_os_id
    FROM dual;
  --
  INSERT INTO tipo_os
   (tipo_os_id,
    empresa_id,
    codigo,
    nome,
    modelo,
    ordem,
    flag_ativo,
    flag_tem_corpo,
    flag_tem_produto,
    flag_tem_itens,
    flag_tem_desc_item,
    flag_tem_meta_item,
    flag_tem_importacao,
    flag_tem_tipo_finan,
    flag_tem_descricao,
    flag_impr_briefing,
    flag_impr_prazo_estim,
    flag_impr_historico,
    flag_item_existente,
    flag_tem_pontos_tam,
    flag_calc_prazo_tam,
    pontos_tam_p,
    pontos_tam_m,
    pontos_tam_g,
    cod_ext_tipo_os,
    status_integracao,
    tam_max_arq_ref,
    qtd_max_arq_ref,
    extensoes_ref,
    tam_max_arq_exe,
    qtd_max_arq_exe,
    extensoes_exe,
    tam_max_arq_apr,
    qtd_max_arq_apr,
    extensoes_apr,
    tam_max_arq_est,
    qtd_max_arq_est,
    extensoes_est,
    tam_max_arq_rfa,
    qtd_max_arq_rfa,
    extensoes_rfa,
    flag_acei_todas,
    tipo_termino_exec,
    flag_pode_pular_aval,
    flag_solic_v_emaval,
    flag_aprov_refaz,
    flag_aprov_devolve,
    flag_solic_alt_arqref,
    flag_exec_alt_arqexe,
    flag_obriga_tam,
    flag_faixa_aprov,
    flag_tem_estim,
    flag_estim_custo,
    flag_estim_prazo,
    flag_estim_arq,
    flag_estim_horas_usu,
    flag_estim_obs,
    flag_exec_estim,
    flag_obriga_apont_exec,
    flag_pode_anexar_arqapr,
    cor_no_quadro,
    flag_solic_pode_encam,
    acoes_executadas,
    acoes_depois,
    num_dias_conc_os,
    flag_habilita_aprov,
    flag_dist_com_ender,
    flag_pode_anexar_arqexe,
    flag_obriga_anexar_arqexe,
    num_max_itens,
    flag_pode_refazer,
    flag_tem_qtd_item,
    modelo_itens,
    flag_depende_out,
    flag_pode_aval_solic,
    flag_pode_aval_exec,
    flag_pode_refaz_em_novo,
    flag_apont_horas_aloc,
    tipo_tela_nova_os)
   SELECT v_tipo_os_id,
          empresa_id,
          p_codigo,
          p_nome,
          modelo,
          ordem,
          flag_ativo,
          flag_tem_corpo,
          flag_tem_produto,
          flag_tem_itens,
          flag_tem_desc_item,
          flag_tem_meta_item,
          flag_tem_importacao,
          flag_tem_tipo_finan,
          flag_tem_descricao,
          flag_impr_briefing,
          flag_impr_prazo_estim,
          flag_impr_historico,
          flag_item_existente,
          flag_tem_pontos_tam,
          flag_calc_prazo_tam,
          pontos_tam_p,
          pontos_tam_m,
          pontos_tam_g,
          cod_ext_tipo_os,
          status_integracao,
          tam_max_arq_ref,
          qtd_max_arq_ref,
          extensoes_ref,
          tam_max_arq_exe,
          qtd_max_arq_exe,
          extensoes_exe,
          tam_max_arq_apr,
          qtd_max_arq_apr,
          extensoes_apr,
          tam_max_arq_est,
          qtd_max_arq_est,
          extensoes_est,
          tam_max_arq_rfa,
          qtd_max_arq_rfa,
          extensoes_rfa,
          flag_acei_todas,
          tipo_termino_exec,
          flag_pode_pular_aval,
          flag_solic_v_emaval,
          flag_aprov_refaz,
          flag_aprov_devolve,
          flag_solic_alt_arqref,
          flag_exec_alt_arqexe,
          flag_obriga_tam,
          flag_faixa_aprov,
          flag_tem_estim,
          flag_estim_custo,
          flag_estim_prazo,
          flag_estim_arq,
          flag_estim_horas_usu,
          flag_estim_obs,
          flag_exec_estim,
          flag_obriga_apont_exec,
          flag_pode_anexar_arqapr,
          cor_no_quadro,
          flag_solic_pode_encam,
          acoes_executadas,
          acoes_depois,
          num_dias_conc_os,
          flag_habilita_aprov,
          flag_dist_com_ender,
          flag_pode_anexar_arqexe,
          flag_obriga_anexar_arqexe,
          num_max_itens,
          flag_pode_refazer,
          flag_tem_qtd_item,
          modelo_itens,
          flag_depende_out,
          flag_pode_aval_solic,
          flag_pode_aval_exec,
          flag_pode_refaz_em_novo,
          flag_apont_horas_aloc,
          tipo_tela_nova_os
     FROM tipo_os
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  -- configura os mesmos eventos para o novo tipo de os
  --
  INSERT INTO evento_config
   (evento_config_id,
    empresa_id,
    evento_id,
    tipo_os_id,
    flag_historico,
    flag_notifica_email,
    flag_notifica_tela,
    notif_corpo,
    email_assunto,
    email_corpo)
   SELECT seq_evento_config.nextval,
          empresa_id,
          evento_id,
          v_tipo_os_id,
          flag_historico,
          flag_notifica_email,
          flag_notifica_tela,
          notif_corpo,
          email_assunto,
          email_corpo
     FROM evento_config
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  -- cria registros de configuracao de notificacoes (eventos)
  evento_pkg.carregar;
  --
  -- cria os motivos para transições de devolução para o novo tipo de os
  INSERT INTO evento_motivo
   (evento_motivo_id,
    empresa_id,
    evento_id,
    tipo_os_id,
    nome,
    ordem,
    tipo_cliente_agencia)
   SELECT seq_evento_motivo.nextval,
          empresa_id,
          evento_id,
          v_tipo_os_id,
          nome,
          ordem,
          tipo_cliente_agencia
     FROM evento_motivo
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
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
          v_tipo_os_id,
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
    WHERE objeto_id = p_tipo_os_duplicar_id
      AND tipo_objeto = 'TIPO_OS';

  -- atribui os mesmos privilégios do tipo de os atual para o novo
  INSERT INTO papel_priv_tos
   (papel_id,
    privilegio_id,
    tipo_os_id,
    abrangencia)
   SELECT papel_id,
          privilegio_id,
          v_tipo_os_id,
          abrangencia
     FROM papel_priv_tos
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  -- atribui o tipo de os novo aos quadros onde o tipo anterior estiver
  INSERT INTO quadro_os_config
   (quadro_coluna_id,
    tipo_os_id,
    status)
   SELECT quadro_coluna_id,
          v_tipo_os_id,
          status
     FROM quadro_os_config
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  -- cria as mesmas transições para o novo tipo de os
  INSERT INTO tipo_os_transicao
   (tipo_os_id,
    os_transicao_id)
   SELECT v_tipo_os_id,
          os_transicao_id
     FROM tipo_os_transicao
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  -- configura os mesmos tipos de produto para derem usados no novo tipo os
  INSERT INTO tipo_prod_tipo_os
   (tipo_os_id,
    tipo_produto_id)
   SELECT v_tipo_os_id,
          tipo_produto_id
     FROM tipo_prod_tipo_os
    WHERE tipo_os_id = p_tipo_os_duplicar_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_os_pkg.xml_gerar(v_tipo_os_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo)) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_OS',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_os_id,
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
  p_tipo_os_id := v_tipo_os_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END duplicar;
 --
--
END; -- TIPO_OS_PKG

/
