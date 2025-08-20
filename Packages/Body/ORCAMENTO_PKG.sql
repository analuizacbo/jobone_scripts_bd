--------------------------------------------------------
--  DDL for Package Body ORCAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ORCAMENTO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Inclusão de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/02/2010  Novo atributo em orcamento (tipo_job_id).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- SIlvia            25/11/2010  Novo atributo data_evento.
  -- Silvia            20/07/2011  Troca da data_evento por data_prev_ini e data_prev_fim.
  -- Silvia            15/07/2015  Grava usuario que criou
  -- Silvia            14/01/2016  Novo parametro item_crono_id (abertura atraves do crono)
  -- Silvia            26/01/2016  Novo parametro usuario_resp_id (abertura atraves do crono)
  -- Silvia            22/06/2016  Novo atributo em orcamento (tipo_financeiro_id).
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  -- Silvia            14/09/2016  Naturezas de item configuraveis.
  -- Silvia            18/10/2016  Implementacao de enderecamento na estimativa.
  -- Silvia            09/05/2017  Implemencacao de Integracao com sistemas externos.
  -- Silvia            11/04/2019  Pega ordem de compra do contrato do job.
  -- Silvia            13/05/2021  Copia servico do job
  -- Silvia            24/07/2023  Nao copia mais a ordem de compra do contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN orcamento.job_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_usuario_resp_id   IN NUMBER,
  p_orcamento_id      OUT orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_num_orcamento      orcamento.num_orcamento%TYPE;
  v_flag_pago_cliente  orcamento.flag_pago_cliente%TYPE;
  v_data_prev_ini      orcamento.data_prev_ini%TYPE;
  v_data_prev_fim      orcamento.data_prev_fim%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_contato_fatur_id   job.contato_fatur_id%TYPE;
  v_emp_faturar_por_id job.emp_faturar_por_id%TYPE;
  v_tipo_job_id        job.tipo_job_id%TYPE;
  v_tipo_financeiro_id job.tipo_financeiro_id%TYPE;
  v_servico_id         job.servico_id%TYPE;
  v_flag_despesa       tipo_financeiro.flag_despesa%TYPE;
  v_objeto_id          item_crono.objeto_id%TYPE;
  v_cod_objeto         item_crono.cod_objeto%TYPE;
  v_cronograma_id      item_crono.cronograma_id%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
  v_papel_id           papel.papel_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_flag_admin         usuario.flag_admin%TYPE;
  v_apelido_resp       pessoa.apelido%TYPE;
  v_xml_atual          CLOB;
  v_contrato_id        contrato.contrato_id%TYPE;
  v_ordem_compra       contrato.ordem_compra%TYPE;
  --
 BEGIN
  v_qt           := 0;
  p_orcamento_id := 0;
  v_lbl_job      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
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
  SELECT numero,
         status,
         contato_fatur_id,
         emp_faturar_por_id,
         flag_pago_cliente,
         tipo_job_id,
         tipo_financeiro_id,
         data_prev_ini,
         data_prev_fim,
         contrato_id,
         servico_id
    INTO v_numero_job,
         v_status_job,
         v_contato_fatur_id,
         v_emp_faturar_por_id,
         v_flag_pago_cliente,
         v_tipo_job_id,
         v_tipo_financeiro_id,
         v_data_prev_ini,
         v_data_prev_fim,
         v_contrato_id,
         v_servico_id
    FROM job
   WHERE job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ORCAMENTO_I', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_item_crono_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono ic,
          cronograma cr
    WHERE ic.item_crono_id = p_item_crono_id
      AND ic.cronograma_id = cr.cronograma_id
      AND cr.job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não existe ou não pertence a esse ' || v_lbl_job || '.';
    RAISE v_exception;
   END IF;
   --
   SELECT objeto_id,
          cod_objeto
     INTO v_objeto_id,
          v_cod_objeto
     FROM item_crono
    WHERE item_crono_id = p_item_crono_id;
   --
   IF v_objeto_id IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma já está associado a algum tipo de objeto.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_objeto IS NOT NULL AND v_cod_objeto <> 'ORCAMENTO'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não pode ser usado para Estimativas de Custos (' ||
                  v_cod_objeto || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_ordem_compra := NULL;
  /* 
    IF v_contrato_id IS NOT NULL THEN
       SELECT ordem_compra
         INTO v_ordem_compra
         FROM contrato
        WHERE contrato_id = v_contrato_id;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_resp_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido_resp
    FROM pessoa
   WHERE usuario_id = p_usuario_resp_id;
  --
  IF length(p_descricao) > 4000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_flag_despesa := 'N';
  IF v_tipo_financeiro_id > 0
  THEN
   SELECT flag_despesa
     INTO v_flag_despesa
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = v_tipo_financeiro_id;
  END IF;
  --
  SELECT nvl(MAX(num_orcamento), 0) + 1
    INTO v_num_orcamento
    FROM orcamento
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_orcamento.nextval
    INTO v_orcamento_id
    FROM dual;
  --
  INSERT INTO orcamento
   (orcamento_id,
    job_id,
    usuario_autor_id,
    usuario_status_id,
    num_orcamento,
    descricao,
    status,
    data_status,
    data_criacao,
    contato_fatur_id,
    emp_faturar_por_id,
    flag_pago_cliente,
    tipo_job_id,
    tipo_financeiro_id,
    data_prev_ini,
    data_prev_fim,
    flag_despesa,
    ordem_compra,
    servico_id)
  VALUES
   (v_orcamento_id,
    p_job_id,
    p_usuario_resp_id,
    p_usuario_sessao_id,
    v_num_orcamento,
    TRIM(p_descricao),
    'PREP',
    SYSDATE,
    SYSDATE,
    v_contato_fatur_id,
    v_emp_faturar_por_id,
    v_flag_pago_cliente,
    v_tipo_job_id,
    v_tipo_financeiro_id,
    v_data_prev_ini,
    v_data_prev_fim,
    v_flag_despesa,
    TRIM(v_ordem_compra),
    v_servico_id);
  --
  ------------------------------------------------------------
  -- gera linhas de totais do orcamento e instancia naturezas 
  -- do item (indices).
  ------------------------------------------------------------
  orcamento_pkg.totais_gerar(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario responsavel
  ------------------------------------------------------------
  IF p_usuario_resp_id = p_usuario_sessao_id AND v_flag_admin = 'S'
  THEN
   orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   v_orcamento_id,
                                   p_usuario_resp_id,
                                   'CRIA',
                                   p_erro_cod,
                                   p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   SELECT nvl(MAX(up.papel_id), 0)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv    pp,
          privilegio    pr,
          papel         pa
    WHERE up.usuario_id = p_usuario_resp_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = 'ORCAMENTO_A';
   --
   IF v_papel_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário responsável não tem privilégio de alterar Estimativas de Custos.';
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel no job, sem co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'N',
                             'N',
                             p_empresa_id,
                             p_job_id,
                             p_usuario_resp_id,
                             v_apelido_resp ||
                             ' indicado como responsável pela Estimativa de Custo ' ||
                             to_char(v_num_orcamento),
                             'Criação de Estimativa de Custos',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel na estimativa como criador
   orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   v_orcamento_id,
                                   p_usuario_resp_id,
                                   'CRIA',
                                   p_erro_cod,
                                   p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel na estimativa 
   orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   v_orcamento_id,
                                   p_usuario_resp_id,
                                   'ENDER',
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
  -- tratamento de cronograma
  ------------------------------------------------------------
  IF nvl(p_item_crono_id, 0) <> 0
  THEN
   -- orcamento criado via cronograma
   UPDATE item_crono
      SET objeto_id  = v_orcamento_id,
          cod_objeto = 'ORCAMENTO'
    WHERE item_crono_id = p_item_crono_id;
   --
   UPDATE orcamento
      SET descricao =
          (SELECT nome
             FROM item_crono
            WHERE item_crono_id = p_item_crono_id)
    WHERE orcamento_id = v_orcamento_id;
  ELSE
   -- orcamento criado por fora do cronograma
   v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
   --
   IF nvl(v_cronograma_id, 0) = 0
   THEN
    -- cria o primeiro cronograma com as atividades obrigatorias
    cronograma_pkg.adicionar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             p_job_id,
                             v_cronograma_id,
                             p_erro_cod,
                             p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- cria a atividade de orcamento
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'ORCAMENTO',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- vincula a atividade de orcamento ao orcamento criado
   UPDATE item_crono
      SET objeto_id = v_orcamento_id,
          nome      = TRIM(substr('Estimativa ' || to_char(v_num_orcamento) || ' ' ||
                                  TRIM(p_descricao),
                                  1,
                                  100))
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORCAMENTO_ADICIONAR',
                           p_empresa_id,
                           v_orcamento_id,
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
  orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_orcamento_id,
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
  p_orcamento_id := v_orcamento_id;
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
 END adicionar;
 --
 --
 PROCEDURE adicionar_demais
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 26/10/2018
  -- DESCRICAO: Inclusão de ORCAMENTOS(s) resultante(s) de repeticoes de um 
  --   determinado grupo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN orcamento.job_id%TYPE,
  p_repet_grupo       IN item_crono.repet_grupo%TYPE,
  p_descricao         IN VARCHAR2,
  p_usuario_resp_id   IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  --
  -- seleciona repeticoes do grupo sem orcamento criado
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          data_mostrar(ic.data_planej_fim) AS data_limite,
          hora_mostrar(ic.data_planej_fim) AS hora_limite
     FROM item_crono ic,
          cronograma cr
    WHERE ic.cronograma_id = cr.cronograma_id
      AND ic.repet_grupo = p_repet_grupo
      AND ic.cod_objeto = 'ORCAMENTO'
      AND cr.job_id = p_job_id
      AND ic.objeto_id IS NULL
    ORDER BY ic.num_seq;
  --
 BEGIN
  FOR r_ic IN c_ic
  LOOP
   orcamento_pkg.adicionar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_job_id,
                           p_descricao,
                           r_ic.item_crono_id,
                           p_usuario_resp_id,
                           v_orcamento_id,
                           p_erro_cod,
                           p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
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
 END adicionar_demais;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Atualização de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2007  Tratamento de flag_pago_cliente
  -- Silvia            24/04/2008  Novo privilegio p/ instrucoes de faturamento.
  -- Silvia            15/07/2009  Retirada de consistencia de valores validos de encargos.
  -- Silvia            02/02/2010  Novo atributo em orcamento (tipo_job_id).
  -- Silvia            25/11/2010  Novo parametro data_evento.
  -- Silvia            07/07/2011  Novo parametro obs_checkin.
  -- Silvia            20/07/2011  Troca da data_evento por data_prev_ini e data_prev_fim.
  -- Silvia            24/11/2014  Aumento de casas decimais (de 2 p/ 6) de percentuais de 
  --                               honorarios e encargos.
  -- Silvia            30/07/2015  Novos parametros (meta min e max)
  -- Silvia            25/04/2016  Nova configuracao no tipo de job p/ substituir o 360.
  -- Silvia            22/06/2016  Novo atributo em orcamento (tipo_financeiro_id).
  -- Silvia            14/09/2016  Naturezas de item configuraveis.
  -- Silvia            09/05/2017  Implemencacao de Integracao com sistemas externos.
  -- Silvia            11/04/2019  Novo atributo ordem_compra.
  -- Silvia            12/01/2021  Novo parametro servico
  -- Silvia            28/06/2021  Retirada do teste obrigatorio de codigo externo.
  -- Joel Dias         29/05/2024  Impedir alteração de orçamentos que não estão em PREP
  -- Ana Luiza         21/10/2024  Removendo obrigatoriedade de arquivo em estimativa
  -- Ana Luiza         06/01/2025  Recalculo orcamento
  -- Ana Luiza         05/11/2024  Implementado novo parametro para atualizar apenas descricao
  -- Ana Luiza         06/08/2025  Obriga tipo_financeiro se parametro ligado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_orcamento_id           IN orcamento.orcamento_id%TYPE,
  p_contato_fatur_id       IN orcamento.contato_fatur_id%TYPE,
  p_emp_faturar_por_id     IN orcamento.emp_faturar_por_id%TYPE,
  p_tipo_job_id            IN orcamento.tipo_job_id%TYPE,
  p_servico_id             IN orcamento.servico_id%TYPE,
  p_tipo_financeiro_id     IN orcamento.tipo_financeiro_id%TYPE,
  p_ordem_compra           IN VARCHAR2,
  p_cod_externo            IN VARCHAR2,
  p_descricao              IN VARCHAR2,
  p_data_prev_ini          IN VARCHAR2,
  p_data_prev_fim          IN VARCHAR2,
  p_meta_valor_min         IN VARCHAR2,
  p_meta_valor_max         IN VARCHAR2,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_uf_servico             IN VARCHAR2,
  p_municipio_servico      IN VARCHAR2,
  p_obs_checkin            IN VARCHAR2,
  p_obs_fatur              IN VARCHAR2,
  p_flag_pago_cliente      IN orcamento.flag_pago_cliente%TYPE,
  p_data_prev_fec_check    IN VARCHAR2,
  p_flag_so_descricao      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_num_orcamento          orcamento.num_orcamento%TYPE;
  v_data_prev_ini          orcamento.data_prev_ini%TYPE;
  v_data_prev_fim          orcamento.data_prev_fim%TYPE;
  v_data_prev_fec_check    orcamento.data_prev_fec_check%TYPE;
  v_status_orcam           orcamento.status%TYPE;
  v_meta_valor_min         orcamento.meta_valor_min%TYPE;
  v_meta_valor_max         orcamento.meta_valor_max%TYPE;
  v_tipo_financeiro_id     orcamento.tipo_financeiro_id%TYPE;
  v_tipo_financeiro_old_id orcamento.tipo_financeiro_id%TYPE;
  v_flag_despesa           orcamento.flag_despesa%TYPE;
  v_flag_despesa_old       orcamento.flag_despesa%TYPE;
  v_servico_id             orcamento.servico_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_tipo_job_id            job.tipo_job_id%TYPE;
  v_flag_alt_tipo_est      tipo_job.flag_alt_tipo_est%TYPE;
  v_atualiz_completa       CHAR(1);
  v_lbl_job                VARCHAR2(100);
  v_lbl_jobs               VARCHAR2(100);
  v_delimitador            CHAR(1);
  v_vetor_natureza_item_id VARCHAR2(1000);
  v_vetor_valor_padrao     VARCHAR2(1000);
  v_natureza_item_id       orcam_nitem_pdr.natureza_item_id%TYPE;
  v_valor_padrao           orcam_nitem_pdr.valor_padrao%TYPE;
  v_valor_padrao_char      VARCHAR2(50);
  v_nome_natureza          natureza_item.nome%TYPE;
  v_mod_calculo            natureza_item.mod_calculo%TYPE;
  v_desc_calculo           VARCHAR2(100);
  v_altera_perc            INTEGER;
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  v_flag_usar_servico      VARCHAR2(10);
  v_obrigar_codext         VARCHAR2(10);
  --v_arq_obr                CHAR(1);
  v_usar_tipo_financeiro CHAR(1);
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_flag_usar_servico    := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_JOB');
  v_obrigar_codext       := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_CODEXT_ORCAM');
  v_usar_tipo_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  --ALCBO_211024
  --v_arq_obr := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_ARQAPROV_ORCAM');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa estimativa de custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         j.tipo_job_id,
         tj.flag_alt_tipo_est,
         o.status,
         o.tipo_financeiro_id,
         o.flag_despesa
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_tipo_job_id,
         v_flag_alt_tipo_est,
         v_status_orcam,
         v_tipo_financeiro_old_id,
         v_flag_despesa_old
    FROM job       j,
         orcamento o,
         tipo_job  tj
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.tipo_job_id = tj.tipo_job_id;
  --
  v_atualiz_completa := 'S';
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   -- verifica se o usuario tem apenas o privilegio p/ alterar instrucoes de faturamento
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'INST_FATUR_C',
                                 p_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_atualiz_completa := 'N';
  END IF;
  --
  SELECT status
    INTO v_status_orcam
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_status_orcam NOT IN ('PREP', 'REAPROV')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do orçamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio de alterar percentuais do job
  SELECT usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_PERC_C', v_job_id, NULL, p_empresa_id)
    INTO v_altera_perc
    FROM dual;
  --ALCBO_211024
  /*
  IF v_arq_obr = 'S' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_orcamento ao,
          arquivo           ar,
          tipo_arquivo      ta
    WHERE ao.orcamento_id = p_orcamento_id
      AND ao.arquivo_id = ar.arquivo_id
      AND ar.tipo_arquivo_id = ta.tipo_arquivo_id
      AND ta.codigo = 'ORCAMENTO_APROV';
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O arquivo de aprovação do cliente é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  */
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de ' || v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o tipo de job da estimativa difere do
  -- tipo de job do job (so pode alterar se estiver configurado - antigo 360).
  IF p_tipo_job_id <> v_tipo_job_id AND v_flag_alt_tipo_est = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de ' || v_lbl_job || ' da Estimativa de Custos só pode ser alterado ' ||
                 'para ' || v_lbl_jobs || ' de tipos específicos.';
   RAISE v_exception;
  END IF;
  --
  -- tratamento especial para servico_id, que pode vir
  -- negativo qdo a chamada for feita via upload de planilha.
  -- nesse caso, o teste de obrigatoriedade eh pulado.
  v_servico_id := p_servico_id;
  --
  --ALCBO_051124
  IF flag_validar(p_flag_so_descricao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag apenas descrição inválida.' || p_flag_so_descricao;
   RAISE v_exception;
  END IF;
  --
  --ALCBO_060825
  IF v_usar_tipo_financeiro = 'N' AND nvl(p_tipo_financeiro_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Tipo Financeiro é obrigatório.';
   RAISE v_exception;
  END IF;
  --So checa outros parametro se p_flag_so_descricao <> 'S'
  IF p_flag_so_descricao <> 'S'
  THEN
   IF nvl(p_tipo_job_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo de ' || v_lbl_job || ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_usar_servico = 'S' AND nvl(v_servico_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do Produto é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_servico_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM servico
     WHERE servico_id = v_servico_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse Produto não existe.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_servico_id <= 0
   THEN
    v_servico_id := NULL;
   END IF;
   --
   IF nvl(p_tipo_financeiro_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_financeiro
     WHERE tipo_financeiro_id = p_tipo_financeiro_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse tipo de financeiro não existe ou não pertence a essa empresa.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- verifica se pode alterar o tipo_financeiro
   IF nvl(p_tipo_financeiro_id, 0) <> nvl(v_tipo_financeiro_old_id, 0)
   THEN
    -- o tipo financeiro mudou.
    -- verifica se a estimativa ja foi aprovada alguma vez
    SELECT COUNT(*)
      INTO v_qt
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND flag_mantem_seq = 'S'
       AND rownum = 1;
    --
    IF v_qt > 0 OR v_status_orcam <> 'PREP'
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O tipo financeiro dessa Estimativa de Custos não pode mais ser alterado.';
     RAISE v_exception;
    END IF;
    --
    v_flag_despesa := 'N';
    IF nvl(p_tipo_financeiro_id, 0) > 0
    THEN
     SELECT flag_despesa
       INTO v_flag_despesa
       FROM tipo_financeiro
      WHERE tipo_financeiro_id = p_tipo_financeiro_id;
    END IF;
    --
    v_tipo_financeiro_id := zvl(p_tipo_financeiro_id, NULL);
   ELSE
    -- o tipo financeiro nao mudou. Mantem as informacoes de antes.
    v_flag_despesa       := v_flag_despesa_old;
    v_tipo_financeiro_id := v_tipo_financeiro_old_id;
   END IF;
   --
   IF length(TRIM(p_ordem_compra)) > 60
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número da Ordem de Compra não pode ter mais que 60 caracteres.';
    RAISE v_exception;
   END IF;
   --
   /*
     IF v_obrigar_codext = 'S' AND TRIM(p_cod_externo) IS NULL THEN
        p_erro_cod := '90000';
        p_erro_msg := 'O preenchimento do código externo é obrigatório.';
        RAISE v_exception;
     END IF;
   */
   --
   IF length(TRIM(p_cod_externo)) > 20
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código externo não pode ter mais que 20 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_despesa = 'S'
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = 'A'
       AND natureza_item = 'CUSTO'
       AND rownum = 1;
    --
    IF v_qt > 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Estimativa de Custos de despesas não deve ter itens de A.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_status_orcam = 'APROV' AND
      (rtrim(p_data_prev_ini) IS NULL OR rtrim(p_data_prev_fim) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento das datas de início e término é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_data_prev_ini) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data prevista de início inválida.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_data_prev_fim) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data prevista de término inválida.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(p_meta_valor_min) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor mínimo da meta inválido (' || p_meta_valor_min || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(p_meta_valor_max) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor máximo da meta inválido (' || p_meta_valor_max || ').';
    RAISE v_exception;
   END IF;
   --
   v_meta_valor_min := moeda_converter(p_meta_valor_min);
   v_meta_valor_max := moeda_converter(p_meta_valor_max);
   --
   IF nvl(v_meta_valor_min, 0) < 0 OR nvl(v_meta_valor_max, 0) < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valores de meta de Estimativa de Custos não podem ser negativos.';
    RAISE v_exception;
   END IF;
   --
   IF v_meta_valor_min > v_meta_valor_max
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor mínimo da meta não pode ser maior do que o valor máximo.';
    RAISE v_exception;
   END IF;
   --
   IF length(p_descricao) > 4000
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A descrição não pode ter mais que 4000 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(p_obs_checkin) > 2000
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'As instruções para check-in não podem ter mais que 2000 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(p_obs_fatur) > 2000
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'As instruções para faturamento não podem ter mais que 2000 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(p_flag_pago_cliente) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag pago pelo cliente inválido.';
    RAISE v_exception;
   END IF;
   --
   v_data_prev_ini := data_converter(p_data_prev_ini);
   v_data_prev_fim := data_converter(p_data_prev_fim);
   --
   IF v_data_prev_ini > v_data_prev_fim
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A data prevista de início não pode ser maior que a data prevista de término.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NULL) OR
      (TRIM(p_uf_servico) IS NULL AND TRIM(p_municipio_servico) IS NOT NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação do local do serviço está incompleta.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NOT NULL
   THEN
    IF cep_pkg.municipio_validar(p_uf_servico, p_municipio_servico) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Município do serviço inválido.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF data_validar(p_data_prev_fec_check) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data prevista para fechamento do check-in inválida.';
    RAISE v_exception;
   END IF;
  END IF; --SO TESTA SE p_flag_so_descricao <> S
  --
  v_data_prev_fec_check := data_converter(p_data_prev_fec_check);
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_051124
  IF p_flag_so_descricao = 'S'
  THEN
   UPDATE orcamento
      SET descricao = TRIM(p_descricao)
    WHERE orcamento_id = p_orcamento_id;
  ELSE
   IF v_atualiz_completa = 'S'
   THEN
    UPDATE orcamento
       SET descricao           = TRIM(p_descricao),
           data_prev_ini       = v_data_prev_ini,
           data_prev_fim       = v_data_prev_fim,
           data_prev_fec_check = v_data_prev_fec_check,
           obs_checkin         = TRIM(p_obs_checkin),
           obs_fatur           = TRIM(p_obs_fatur),
           contato_fatur_id    = zvl(p_contato_fatur_id, NULL),
           emp_faturar_por_id  = zvl(p_emp_faturar_por_id, NULL),
           uf_servico          = upper(p_uf_servico),
           municipio_servico   = TRIM(p_municipio_servico),
           flag_pago_cliente   = p_flag_pago_cliente,
           tipo_job_id         = p_tipo_job_id,
           meta_valor_min      = v_meta_valor_min,
           meta_valor_max      = v_meta_valor_max,
           tipo_financeiro_id  = v_tipo_financeiro_id,
           flag_despesa        = v_flag_despesa,
           ordem_compra        = TRIM(p_ordem_compra),
           cod_externo         = TRIM(p_cod_externo),
           servico_id          = v_servico_id
     WHERE orcamento_id = p_orcamento_id;
    --
   
    ------------------------------------------------------------
    -- tratamento do vetor de naturezas do item
    ------------------------------------------------------------
    IF v_altera_perc = 1
    THEN
     -- apenas usuario com priv de alterar percentuais
     DELETE FROM orcam_nitem_pdr
      WHERE orcamento_id = p_orcamento_id;
     --
     v_delimitador            := '|';
     v_vetor_natureza_item_id := rtrim(p_vetor_natureza_item_id);
     v_vetor_valor_padrao     := rtrim(p_vetor_valor_padrao);
     --
     WHILE nvl(length(rtrim(v_vetor_natureza_item_id)), 0) > 0
     LOOP
      v_natureza_item_id  := nvl(to_number(prox_valor_retornar(v_vetor_natureza_item_id,
                                                               v_delimitador)),
                                 0);
      v_valor_padrao_char := prox_valor_retornar(v_vetor_valor_padrao, v_delimitador);
      --
      SELECT COUNT(*)
        INTO v_qt
        FROM natureza_item
       WHERE natureza_item_id = v_natureza_item_id
         AND empresa_id = p_empresa_id;
      --
      IF v_qt = 0
      THEN
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
      IF v_mod_calculo = 'NA'
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa natureza de item não se aplica para cálculos (' || v_nome_natureza || ').';
       RAISE v_exception;
      END IF;
      --
      IF numero_validar(v_valor_padrao_char) = 0
      THEN
       p_erro_cod := '90000';
       p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' ||
                     v_valor_padrao_char || ').';
       RAISE v_exception;
      END IF;
      --
      v_valor_padrao := numero_converter(v_valor_padrao_char);
      --
      IF v_valor_padrao IS NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O preenchimento do ' || v_desc_calculo || ' para ' || v_nome_natureza ||
                     ' é obrigatório.';
       RAISE v_exception;
      END IF;
      --
      INSERT INTO orcam_nitem_pdr
       (orcamento_id,
        natureza_item_id,
        valor_padrao)
      VALUES
       (p_orcamento_id,
        v_natureza_item_id,
        nvl(v_valor_padrao, 0));
     END LOOP;
     --
     orcamento_pkg.totais_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF; -- fim do IF v_altera_perc = 1
   ELSE
    -- nao eh atualizacao completa
    UPDATE orcamento
       SET obs_checkin = TRIM(p_obs_checkin),
           obs_fatur   = TRIM(p_obs_fatur)
     WHERE orcamento_id = p_orcamento_id;
   END IF;
  END IF; --NAO ATUALIZA SO DESCRICAO PARA ATUALIZAR
  /* --ALCBO_060125
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;*/
  --
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORCAMENTO_ATUALIZAR',
                           p_empresa_id,
                           p_orcamento_id,
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
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 PROCEDURE desc_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 05/12/2011
  -- DESCRICAO: Atualização da descricao do ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET descricao = TRIM(p_descricao)
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := 'Alteração da descrição';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END; -- desc_atualizar
 --
 --
 PROCEDURE ordem_compra_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 30/04/2020
  -- DESCRICAO: Atualização da ordem de compra do ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_ordem_compra      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_ordem_compra)) > 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da Ordem de Compra não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET ordem_compra = TRIM(p_ordem_compra)
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := 'Alteração da ordem de compra';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END ordem_compra_atualizar;
 --
 --
 PROCEDURE autor_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/02/2016
  -- DESCRICAO: Atualização do usuario autor do ORCAMENTO (vai deixar de existir)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_usuario_autor_id  IN orcamento.usuario_autor_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_autor_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET usuario_autor_id = p_usuario_autor_id
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := 'Alteração do autor/responsável';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END autor_atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Exclusão de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/07/2014  Deixa excluir estimativa pronta pois nao existe como 
  --                               voltar o status para em preparacao.
  -- Silvia            19/01/2016  Tratamento de cronograma
  -- Silvia            08/09/2016  Exclusao automatica de orcam_nitem_pdr.
  -- Silvia            18/10/2016  Exclusao automatica de orcam_usuario.
  -- Silvia            09/05/2017  Implemencacao de Integracao com sistemas externos.
  -- Silvia            25/06/2021  Exclusao automatica dos arquivos.
  -- Silvia            13/07/2023  Consistencia de sobras.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  --
  CURSOR c_arq IS
   SELECT arquivo_id
     FROM arquivo_orcamento
    WHERE orcamento_id = p_orcamento_id;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_E',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam NOT IN ('PREP', 'EMAPRO', 'REPROV')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota ie,
         item      it
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = ie.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos já tem notas fiscais associadas a itens.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_carta ie,
         item       it
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = ie.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos já tem cartas acordo associadas a itens.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur ie,
         item       it
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = ie.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos já tem faturamentos associados a itens.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_abat ia,
         item      it
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = ia.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos já tem abatimentos associados a itens.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_sobra ia,
         item       it
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = ia.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos já tem sobras associadas a itens.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORCAMENTO_EXCLUIR',
                           p_empresa_id,
                           p_orcamento_id,
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
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_orcamento_id,
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
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq IN c_arq
  LOOP
   DELETE FROM arquivo_orcamento
    WHERE arquivo_id = r_arq.arquivo_id
      AND orcamento_id = p_orcamento_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq.arquivo_id;
  END LOOP;
  --
  DELETE FROM item_decup ie
   WHERE EXISTS (SELECT 1
            FROM item it
           WHERE it.orcamento_id = p_orcamento_id
             AND it.item_id = ie.item_id);
  --
  DELETE FROM item_hist ie
   WHERE EXISTS (SELECT 1
            FROM item it
           WHERE it.orcamento_id = p_orcamento_id
             AND it.item_id = ie.item_id);
  --
  DELETE FROM parcela ie
   WHERE EXISTS (SELECT 1
            FROM item it
           WHERE it.orcamento_id = p_orcamento_id
             AND it.item_id = ie.item_id);
  --
  DELETE FROM item
   WHERE orcamento_id = p_orcamento_id;
  DELETE FROM orcam_nitem_pdr
   WHERE orcamento_id = p_orcamento_id;
  DELETE FROM orcam_usuario
   WHERE orcamento_id = p_orcamento_id;
  DELETE FROM orcam_fluxo_aprov
   WHERE orcamento_id = p_orcamento_id;
  DELETE FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  UPDATE item_crono ic
     SET objeto_id = NULL
   WHERE cod_objeto = 'ORCAMENTO'
     AND objeto_id = p_orcamento_id;
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
 PROCEDURE copiar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 28/01/2009
  -- DESCRICAO: Copia um determinado orcamento de um job para outro.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/02/2010  Novo atributo em orcamento (tipo_job_id).
  -- Silvia            25/11/2010  Novo atributo data_evento.
  -- Silvia            12/05/2014  Novo atributo do item flag_com_encargo.
  -- Silvia            14/10/2014  Novo atributo do item flag_com_encargo_honor.
  -- Silvia            19/01/2016  Tratamento de cronograma
  -- Silvia            25/04/2016  Nova configuracao no tipo de job p/ substituir o 360.
  -- Silvia            22/06/2016  Novo atributo em orcamento (tipo_financeiro_id).
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  -- Silvia            14/09/2016  Naturezas de item configuraveis.
  -- Silvia            18/10/2016  Implementacao de enderecamento na estimativa.
  -- Silvia            09/05/2017  Implemencacao de Integracao com sistemas externos.
  -- Silvia            11/04/2019  Pega ordem de compra do contrato do job.
  -- Silvia            24/07/2023  Nao copia mais a ordem de compra do contrato
  -- Ana Luiza         19/02/2025  Adicionado cópia de cod_externo do orcamento
  -- Ana Luiza         19/02/2025  Adicionado cópia de cod_externo do item
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job_de        IN VARCHAR2,
  p_num_orcam_de      IN VARCHAR2,
  p_job_para_id       IN job.job_id%TYPE,
  p_orcam_para_id     OUT orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_orcam_de_id            orcamento.orcamento_id%TYPE;
  v_orcam_para_id          orcamento.orcamento_id%TYPE;
  v_num_orcam_para         orcamento.num_orcamento%TYPE;
  v_descricao              orcamento.descricao%TYPE;
  v_tipo_job_id            orcamento.tipo_job_id%TYPE;
  v_tipo_job_de_id         orcamento.tipo_job_id%TYPE;
  v_tipo_job_para_id       orcamento.tipo_job_id%TYPE;
  v_flag_alt_tipo_est_para tipo_job.flag_alt_tipo_est%TYPE;
  v_job_de_id              job.job_id%TYPE;
  v_numero_job_para        job.numero%TYPE;
  v_status_job_para        job.status%TYPE;
  v_item_id                item.item_id%TYPE;
  v_cronograma_id          item_crono.cronograma_id%TYPE;
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_flag_admin             usuario.flag_admin%TYPE;
  v_papel_id               papel.papel_id%TYPE;
  v_xml_atual              CLOB;
  v_contrato_id            contrato.contrato_id%TYPE;
  v_ordem_compra           contrato.ordem_compra%TYPE;
  --
  CURSOR c_it IS
   SELECT item_id,
          tipo_produto_id,
          fornecedor_id,
          grupo,
          subgrupo,
          complemento,
          natureza_item,
          tipo_item,
          num_seq,
          quantidade,
          frequencia,
          unidade_freq,
          custo_unitario,
          valor_aprovado,
          valor_fornecedor,
          perc_bv,
          perc_imposto,
          tipo_fatur_bv,
          ordem_grupo,
          ordem_subgrupo,
          ordem_item,
          ordem_grupo_sq,
          ordem_subgrupo_sq,
          ordem_item_sq,
          flag_sem_valor,
          flag_com_honor,
          flag_com_encargo,
          flag_com_encargo_honor,
          obs,
          flag_pago_cliente,
          cod_externo
     FROM item
    WHERE orcamento_id = v_orcam_de_id
      AND natureza_item = 'CUSTO'
    ORDER BY ordem_grupo,
             ordem_subgrupo,
             ordem_item,
             tipo_item;
  --
 BEGIN
  v_qt            := 0;
  p_orcam_para_id := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(flag_admin)
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF rtrim(p_num_orcam_de) IS NULL OR inteiro_validar(p_num_orcam_de) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da Estimativa de Custos inválido (' || p_num_orcam_de || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_num_job_de) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do ' || v_lbl_job || ' não informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(job_id)
    INTO v_job_de_id
    FROM job
   WHERE numero = TRIM(p_num_job_de)
     AND empresa_id = p_empresa_id;
  --
  IF v_job_de_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe (' || p_num_job_de || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(oc.orcamento_id),
         MAX(oc.tipo_job_id),
         MAX(oc.descricao)
    INTO v_orcam_de_id,
         v_tipo_job_de_id,
         v_descricao
    FROM orcamento oc
   WHERE job_id = v_job_de_id
     AND num_orcamento = to_number(p_num_orcam_de);
  --
  IF v_orcam_de_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe nesse ' || v_lbl_job || ' (' || p_num_job_de || '/' ||
                 p_num_orcam_de || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(j.numero),
         MAX(j.status),
         MAX(j.tipo_job_id),
         MAX(j.contrato_id)
    INTO v_numero_job_para,
         v_status_job_para,
         v_tipo_job_para_id,
         v_contrato_id
    FROM job j
   WHERE j.job_id = p_job_para_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_numero_job_para IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' de destino não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_alt_tipo_est
    INTO v_flag_alt_tipo_est_para
    FROM tipo_job
   WHERE tipo_job_id = v_tipo_job_para_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_I',
                                p_job_para_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job_para NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' de destino não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_alt_tipo_est_para = 'S'
  THEN
   -- o novo orcamento vai herdar o tipo do orcamento de origem
   v_tipo_job_id := v_tipo_job_de_id;
  ELSE
   -- o novo orcamento vai manter o tipo do job destino
   v_tipo_job_id := v_tipo_job_para_id;
  END IF;
  --
  v_ordem_compra := NULL;
  /*
    IF v_contrato_id IS NOT NULL THEN
       SELECT ordem_compra
         INTO v_ordem_compra
         FROM contrato
        WHERE contrato_id = v_contrato_id;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(num_orcamento), 0) + 1
    INTO v_num_orcam_para
    FROM orcamento
   WHERE job_id = p_job_para_id;
  --
  SELECT seq_orcamento.nextval
    INTO v_orcam_para_id
    FROM dual;
  --
  INSERT INTO orcamento
   (orcamento_id,
    job_id,
    usuario_autor_id,
    usuario_status_id,
    num_orcamento,
    descricao,
    status,
    data_status,
    data_criacao,
    contato_fatur_id,
    emp_faturar_por_id,
    flag_pago_cliente,
    municipio_servico,
    uf_servico,
    obs_checkin,
    obs_fatur,
    tipo_job_id,
    data_prev_ini,
    data_prev_fim,
    tipo_financeiro_id,
    flag_despesa,
    ordem_compra,
    servico_id,
    cod_externo) --ALCBO_190225
   SELECT v_orcam_para_id,
          p_job_para_id,
          p_usuario_sessao_id,
          p_usuario_sessao_id,
          v_num_orcam_para,
          descricao,
          'PREP',
          SYSDATE,
          SYSDATE,
          contato_fatur_id,
          emp_faturar_por_id,
          flag_pago_cliente,
          municipio_servico,
          uf_servico,
          obs_checkin,
          obs_fatur,
          v_tipo_job_id,
          data_prev_ini,
          data_prev_fim,
          tipo_financeiro_id,
          flag_despesa,
          TRIM(v_ordem_compra),
          servico_id,
          cod_externo --ALCBO_190225
     FROM orcamento
    WHERE orcamento_id = v_orcam_de_id;
  --
  ------------------------------------------------------------
  -- copia indices do job e gera linhas de totais do orcamento
  ------------------------------------------------------------
  orcamento_pkg.totais_gerar(p_usuario_sessao_id, v_orcam_para_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- copia itens de CUSTO
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   SELECT seq_item.nextval
     INTO v_item_id
     FROM dual;
   --
   INSERT INTO item
    (item_id,
     job_id,
     orcamento_id,
     tipo_produto_id,
     fornecedor_id,
     grupo,
     subgrupo,
     complemento,
     natureza_item,
     tipo_item,
     num_seq,
     quantidade,
     frequencia,
     unidade_freq,
     custo_unitario,
     valor_aprovado,
     valor_fornecedor,
     perc_bv,
     tipo_fatur_bv,
     perc_imposto,
     ordem_grupo,
     ordem_subgrupo,
     ordem_item,
     ordem_grupo_sq,
     ordem_subgrupo_sq,
     ordem_item_sq,
     flag_parcelado,
     flag_sem_valor,
     flag_com_honor,
     flag_com_encargo,
     flag_com_encargo_honor,
     flag_pago_cliente,
     status_fatur,
     obs,
     cod_externo) --ALCBO_190225
   VALUES
    (v_item_id,
     p_job_para_id,
     v_orcam_para_id,
     r_it.tipo_produto_id,
     r_it.fornecedor_id,
     r_it.grupo,
     r_it.subgrupo,
     r_it.complemento,
     r_it.natureza_item,
     r_it.tipo_item,
     r_it.num_seq,
     r_it.quantidade,
     r_it.frequencia,
     r_it.unidade_freq,
     r_it.custo_unitario,
     r_it.valor_aprovado,
     r_it.valor_fornecedor,
     r_it.perc_bv,
     r_it.tipo_fatur_bv,
     r_it.perc_imposto,
     r_it.ordem_grupo,
     r_it.ordem_subgrupo,
     r_it.ordem_item,
     r_it.ordem_grupo_sq,
     r_it.ordem_subgrupo_sq,
     r_it.ordem_item_sq,
     'N',
     r_it.flag_sem_valor,
     r_it.flag_com_honor,
     r_it.flag_com_encargo,
     r_it.flag_com_encargo_honor,
     r_it.flag_pago_cliente,
     'NLIB',
     r_it.obs,
     r_it.cod_externo); --ALCBO_190225
   --
   INSERT INTO item_decup
    (item_decup_id,
     item_id,
     descricao,
     ordem_decup)
    SELECT seq_item_decup.nextval,
           v_item_id,
           descricao,
           ordem_decup
      FROM item_decup
     WHERE item_id = r_it.item_id;
   --
   item_pkg.historico_gerar(p_usuario_sessao_id,
                            v_item_id,
                            'CRIACAO',
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- recalcula totais do orcamento
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcam_para_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- trata os status de check-in e faturamento do job
  job_pkg.status_tratar(p_usuario_sessao_id,
                        p_empresa_id,
                        p_job_para_id,
                        'ALL',
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario responsavel - exceto admin
  ------------------------------------------------------------
  IF v_flag_admin = 'S'
  THEN
   NULL;
  ELSE
   SELECT nvl(MAX(up.papel_id), 0)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv    pp,
          privilegio    pr,
          papel         pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = 'ORCAMENTO_A';
   --
   IF v_papel_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário responsável não tem privilégio de alterar Estimativa de Custos.';
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel no job, sem co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'N',
                             'N',
                             p_empresa_id,
                             p_job_para_id,
                             p_usuario_sessao_id,
                             'Copiou Estimativa de Custos',
                             'Cópia de Estimativa de Custos',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel na estimativa como criador
   orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   v_orcam_para_id,
                                   p_usuario_sessao_id,
                                   'CRIA',
                                   p_erro_cod,
                                   p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca usuario responsavel na estimativa 
   orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                   'N',
                                   p_empresa_id,
                                   v_orcam_para_id,
                                   p_usuario_sessao_id,
                                   'ENDER',
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
  -- tratamento de cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_para_id);
  --
  IF nvl(v_cronograma_id, 0) = 0
  THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            p_job_para_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- cria a atividade de orcamento
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'ORCAMENTO',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- vincula a atividade de orcamento ao orcamento criado
  UPDATE item_crono
     SET objeto_id = v_orcam_para_id,
         nome      = TRIM(substr('Estimativa de Custos ' || to_char(v_num_orcam_para) || ' ' ||
                                 TRIM(v_descricao),
                                 1,
                                 100))
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORCAMENTO_ADICIONAR',
                           p_empresa_id,
                           v_orcam_para_id,
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
  orcamento_pkg.xml_gerar(v_orcam_para_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(v_orcam_para_id);
  v_compl_histor   := 'Copiado da Estimativa de Custos ' || TRIM(p_num_job_de) || '/' ||
                      TRIM(p_num_orcam_de);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_orcam_para_id,
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
  p_orcam_para_id := v_orcam_para_id;
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
 END; -- copiar
 --
 --
 PROCEDURE arquivar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Arquivamento de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2015  Grava usuario que arquivou
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam NOT IN ('PREP', 'REPROV', 'EMAPRO')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item      it,
         item_nota no
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = no.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não pode ser arquivada pois existem ' ||
                 'itens associados a notas fiscais.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item       it,
         item_fatur fa
   WHERE it.orcamento_id = p_orcamento_id
     AND it.item_id = fa.item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não pode ser arquivada pois existem ' ||
                 'itens associados a faturamentos.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'ARQUI',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ARQUIVAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END; -- arquivar
 --
 --
 PROCEDURE desarquivar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Desarquivamento de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2015  Grava usuario que desarquivou
  -- Silvia            23/12/2015  Passa status para PREP
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam <> 'ARQUI'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não se encontra arquivada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'PREP',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'DESARQUIVAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END; -- desarquivar
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: Passa o ORCAMENTO para em aprovacao ou aprova automaticamente.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/08/2008  Consistencia de itens com tipo de produto nao definido.
  -- Silvia            28/05/2014  Retirada de parametros e tasks.
  -- Silvia            15/07/2015  Grava usuario que terminou
  -- Silvia            16/11/2015  Recalcula numeracao dos itens.
  -- Silvia            01/06/2022  Teste de faixa de aprovacao
  -- Ana Luiza         21/10/2024  Adicionado obrigatoriedade arquivo
  -- Ana Luiza         02/04/2025  Adicionado obrigatoriedade arquivo
  -- Ana Luiza         06/08/2025  Obriga tipo_financeiro se parametro ligado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_num_orcamento        orcamento.num_orcamento%TYPE;
  v_status_orcam         orcamento.status%TYPE;
  v_data_aprov_limite    orcamento.data_aprov_limite%TYPE;
  v_numero_job           job.numero%TYPE;
  v_status_job           job.status%TYPE;
  v_job_id               job.job_id%TYPE;
  v_flag_apr_orcam_auto  tipo_job.flag_apr_orcam_auto%TYPE;
  v_faixa_aprov_id       faixa_aprov.faixa_aprov_id%TYPE;
  v_lbl_job              VARCHAR2(100);
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
  v_usar_tipo_financeiro CHAR(1);
  --ALCBO_211024 --ALCBO_020425
  --v_arq_obr CHAR(1);
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_usar_tipo_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  --ALCBO_020425
  --v_arq_obr := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_ARQAPROV_ORCAM');
  --
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status,
         t.flag_apr_orcam_auto
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam,
         v_flag_apr_orcam_auto
    FROM job       j,
         orcamento o,
         tipo_job  t
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam NOT IN ('PREP', 'REPROV')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --ALCBO_060825
  SELECT COUNT(tipo_financeiro_id)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --ALCBO_060825
  IF v_usar_tipo_financeiro = 'N' AND v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Tipo Financeiro é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE orcamento_id = p_orcamento_id
     AND natureza_item = 'CUSTO';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não tem itens.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item         it,
         tipo_produto tp
   WHERE it.orcamento_id = p_orcamento_id
     AND it.tipo_produto_id = tp.tipo_produto_id
     AND tp.codigo = 'ND'
     AND natureza_item = 'CUSTO';
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos tem itens com tipo de produto não definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_apr_orcam_auto = 'N'
  THEN
   -- verifica se existem aprovadores configurados
   SELECT COUNT(*)
     INTO v_qt
     FROM faixa_aprov       fa,
          faixa_aprov_papel fp
    WHERE fa.empresa_id = p_empresa_id
      AND fa.tipo_faixa = 'EC'
      AND fa.flag_ativo = 'S'
      AND fa.faixa_aprov_id = fp.faixa_aprov_id
      AND EXISTS (SELECT 1
             FROM usuario_papel up,
                  usuario       us
            WHERE up.papel_id = fp.papel_id
              AND up.usuario_id = us.usuario_id
              AND us.flag_admin = 'N'
              AND us.flag_ativo = 'S'
              AND usuario_pkg.priv_verificar(us.usuario_id,
                                             'ORCAMENTO_AP',
                                             p_orcamento_id,
                                             NULL,
                                             p_empresa_id) = 1);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível terminar a Estimativa de Custos pois não há ' ||
                  'usuário(s) aprovador(es) configurados para aprová-la.';
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_211024 --ALCBO_020425
  /*IF v_arq_obr = 'S' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_orcamento ao,
          arquivo           ar,
          tipo_arquivo      ta
    WHERE ao.orcamento_id = p_orcamento_id
      AND ao.arquivo_id = ar.arquivo_id
      AND ar.tipo_arquivo_id = ta.tipo_arquivo_id
      AND ta.codigo = 'ORCAMENTO_APROV';
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O arquivo de aprovação do cliente é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;*/
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_APROV_ORCAM',
                                                             0);
  UPDATE orcamento
     SET status            = 'EMAPRO',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id,
         motivo_status     = NULL,
         compl_status      = NULL,
         data_aprov_limite = v_data_aprov_limite
   WHERE orcamento_id = p_orcamento_id;
  --
  -- endereca usuario na estimativa como usuario que terminou
  orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                  'N',
                                  p_empresa_id,
                                  p_orcamento_id,
                                  p_usuario_sessao_id,
                                  'TERM',
                                  p_erro_cod,
                                  p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- recalcula o numero sequencial dos itens do orcamento 
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'TERMINAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
  IF v_flag_apr_orcam_auto = 'S'
  THEN
   -- aprova a estimativa automaticamente
   orcamento_pkg.aprovar(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         p_orcamento_id,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- marca a estimativa como tendo transicao de aprovacao (o padrao na hora de 
   -- criar a estimativa eh nao.
   UPDATE orcamento
      SET flag_com_aprov = 'S'
    WHERE orcamento_id = p_orcamento_id;
   --
   -- deleta eventual historico de aprovacao e instancia
   -- o novo fluxo de aprovacao.
   DELETE FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id;
   --
   SELECT MAX(faixa_aprov_id)
     INTO v_faixa_aprov_id
     FROM faixa_aprov
    WHERE empresa_id = p_empresa_id
      AND tipo_faixa = 'EC'
      AND flag_ativo = 'S';
   --
   INSERT INTO orcam_fluxo_aprov
    (orcamento_id,
     papel_id,
     seq_aprov)
    SELECT p_orcamento_id,
           papel_id,
           seq_aprov
      FROM faixa_aprov_papel
     WHERE faixa_aprov_id = v_faixa_aprov_id;
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
 END; -- terminar
 --
 --
 PROCEDURE retomar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/07/2015
  -- DESCRICAO: Retorna o ORCAMENTO para em preparacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam NOT IN ('EMAPRO')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'PREP',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE orcamento_id = p_orcamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'RETOMAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
 END retomar;
 --
 --
 PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: Marca o ORCAMENTO como aprovado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/11/2010  Troca do evento de alteracao para aprovacao.
  --                               Implementacao de data_aprovacao (1ra aprovacao).
  -- Silvia            20/07/2011  Verificacao das datas de inicio e termino do orcamento.
  -- Silvia            28/05/2014  Retirada de parametros e tasks.
  -- Silvia            15/07/2015  Grava usuario aprovador
  -- Silvia            16/11/2015  Salva numeracao dos itens na aprovacao.
  -- Silvia            13/04/2021  Consistencia de arquivo de aprovacao obrigatorio
  -- Silvia            25/06/2021  Consistencia do codigo externo obrigatorio
  -- Silvia            02/06/2022  Grava aprovacao em orcam_fluxo_aprov
  -- Silvia            02/02/2022  Novo ponto de integracao JOB_APROV_ORCAM_ENVIAR
  --                               no lugar do antigo JOB_ATUALIZAR
  -- Ana Luiza         21/10/2024  Adicionado verificacao que faz na web no banco par arquivo
  -- Ana Luiza         06/01/2025  Adicao de recalculo de item
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_num_orcamento       orcamento.num_orcamento%TYPE;
  v_status_orcam        orcamento.status%TYPE;
  v_data_aprovacao      orcamento.data_aprovacao%TYPE;
  v_cod_externo         orcamento.cod_externo%TYPE;
  v_emp_faturar_por_id  orcamento.emp_faturar_por_id%TYPE;
  v_data_prev_fec_check orcamento.data_prev_fec_check%TYPE;
  v_seq_aprov           orcam_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_maior     orcam_fluxo_aprov.seq_aprov%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_job_id              job.job_id%TYPE;
  v_cliente_id          job.cliente_id%TYPE;
  v_data_prev_ini       orcamento.data_prev_ini%TYPE;
  v_data_prev_fim       orcamento.data_prev_fim%TYPE;
  v_papel_id            papel.papel_id%TYPE;
  v_qtd_aprov_max       faixa_aprov_papel.seq_aprov%TYPE;
  v_qtd_aprov_atu       faixa_aprov_papel.seq_aprov%TYPE;
  v_aprov_final         NUMBER(5);
  v_lbl_job             VARCHAR2(100);
  v_arq_obr             VARCHAR2(10);
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  v_obrigar_codext      VARCHAR2(10);
  v_aprovadores         VARCHAR2(4000);
  --
  CURSOR c_item IS
   SELECT item_id,
          natureza_item
     FROM item
    WHERE orcamento_id = p_orcamento_id;
  --
  CURSOR c_ap IS
   SELECT pe.apelido AS aprovador
     FROM orcam_fluxo_aprov oa,
          pessoa            pe
    WHERE oa.orcamento_id = p_orcamento_id
      AND oa.usuario_id = pe.usuario_id
    ORDER BY oa.seq_aprov,
             oa.data_status;
  --
 BEGIN
  v_qt             := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_arq_obr        := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_ARQAPROV_ORCAM');
  v_obrigar_codext := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_CODEXT_ORCAM');
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
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status,
         o.data_aprovacao,
         j.cliente_id,
         o.emp_faturar_por_id,
         o.data_prev_ini,
         o.data_prev_fim,
         o.cod_externo
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam,
         v_data_aprovacao,
         v_cliente_id,
         v_emp_faturar_por_id,
         v_data_prev_ini,
         v_data_prev_fim,
         v_cod_externo
    FROM job       j,
         orcamento o,
         pessoa    p
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.cliente_id = p.pessoa_id;
  --
  IF p_flag_commit = 'S'
  THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_AP',
                                 p_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam <> 'EMAPRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE orcamento_id = p_orcamento_id
     AND natureza_item = 'CUSTO';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não tem itens.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(v_data_prev_ini) IS NULL OR rtrim(v_data_prev_fim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As datas de início e término da Estimativa de Custos não foram informadas.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_aprovacao IS NULL
  THEN
   -- o orcamento nunca foi aprovado. Usa a data de hoje.
   -- Caso contrario, mantem a data da 1ra aprovacao.
   v_data_aprovacao := SYSDATE;
  END IF;
  --
  v_data_prev_fec_check := trunc(SYSDATE) + nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                                         'NUM_DIAS_FECHA_CHECKIN')),
                                                0);
  --ALCBO_211024
  IF v_arq_obr = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_orcamento ao,
          arquivo           ar,
          tipo_arquivo      ta
    WHERE ao.orcamento_id = p_orcamento_id
      AND ao.arquivo_id = ar.arquivo_id
      AND ar.tipo_arquivo_id = ta.tipo_arquivo_id
      AND ta.codigo = 'ORCAMENTO_APROV';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O arquivo de aprovação do cliente é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_obrigar_codext = 'S' AND TRIM(v_cod_externo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código externo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_qtd_aprov_atu := 0;
  v_qtd_aprov_max := 0;
  v_aprov_final   := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_fluxo_aprov
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt > 0 AND p_flag_commit = 'S'
  THEN
   -- existe fluxo de aprovacao e eh uma aprovacao via tela.
   -- assume que a aprovacao deve obedecer a sequencia.
   -- pega a maior sequencia ja aprovada.
   SELECT nvl(MAX(seq_aprov), 0)
     INTO v_seq_aprov_maior
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id
      AND data_status IS NOT NULL;
   --
   -- pega a proxima sequencia com aprovacao pendente
   SELECT nvl(MIN(seq_aprov), 0)
     INTO v_seq_aprov
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id
      AND data_status IS NULL
      AND seq_aprov > v_seq_aprov_maior;
   --
   -- Verifica o papel do usuario que pode aprovar nessa sequencia.
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up
    WHERE up.usuario_id = p_usuario_sessao_id
      AND EXISTS (SELECT 1
             FROM papel_priv pp,
                  privilegio pr
            WHERE up.papel_id = pp.papel_id
              AND pp.privilegio_id = pr.privilegio_id
              AND pr.codigo = 'ORCAMENTO_AP')
      AND EXISTS (SELECT 1
             FROM orcam_fluxo_aprov oa
            WHERE oa.orcamento_id = p_orcamento_id
              AND oa.papel_id = up.papel_id
              AND oa.seq_aprov = v_seq_aprov
              AND oa.data_status IS NULL);
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não tem papel de aprovador para essa sequência ' || to_char(v_seq_aprov) || '.';
    RAISE v_exception;
   END IF;
   --
   UPDATE orcam_fluxo_aprov
      SET usuario_id  = p_usuario_sessao_id,
          status      = 'APROV',
          data_status = SYSDATE
    WHERE orcamento_id = p_orcamento_id
      AND papel_id = v_papel_id
      AND seq_aprov = v_seq_aprov;
   --
   -- Verifica qtd de aprovacoes.
   SELECT COUNT(DISTINCT seq_aprov)
     INTO v_qtd_aprov_atu
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id
      AND data_status IS NOT NULL;
   --
   SELECT nvl(MAX(seq_aprov), 0)
     INTO v_qtd_aprov_max
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id;
  END IF;
  --
  IF v_qtd_aprov_atu >= v_qtd_aprov_max
  THEN
   -- orcamento sem fluxo de aprovacao ou atingiu a qtd necessaria de 
   -- aprovacoes. Pode mudar de status.
   v_aprov_final := 1;
   --
   UPDATE orcamento
      SET status              = 'APROV',
          data_status         = SYSDATE,
          data_aprovacao      = v_data_aprovacao,
          data_prev_fec_check = v_data_prev_fec_check,
          usuario_status_id   = p_usuario_sessao_id
    WHERE orcamento_id = p_orcamento_id;
  END IF;
  --
  -- endereca usuario na estimativa como aprovador
  orcamento_pkg.enderecar_usuario(p_usuario_sessao_id,
                                  'N',
                                  p_empresa_id,
                                  p_orcamento_id,
                                  p_usuario_sessao_id,
                                  'APROV',
                                  p_erro_cod,
                                  p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_aprovadores := NULL;
  IF v_aprov_final = 1
  THEN
   -- recupera todos os aprovadores p/ guardar no hitorico
   FOR r_ap IN c_ap
   LOOP
    v_aprovadores := v_aprovadores || ', ' || TRIM(r_ap.aprovador);
   END LOOP;
   --
   -- retira a primeira virgula
   v_aprovadores := TRIM(substr(v_aprovadores, 3));
  END IF;
  --
  IF v_aprov_final = 1
  THEN
   -- recalcula o numero sequencial dos itens do orcamento 
   orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera historico dos itens
   FOR r_item IN c_item
   LOOP
    IF r_item.natureza_item = 'CUSTO'
    THEN
     --ALCBO_060125
     item_pkg.valores_recalcular(p_usuario_sessao_id, r_item.item_id, p_erro_cod, p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     item_pkg.historico_gerar(p_usuario_sessao_id,
                              r_item.item_id,
                              'APROVACAO',
                              NULL,
                              p_erro_cod,
                              p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     -- salva/fixa a numeracao sequencial
     UPDATE item
        SET flag_mantem_seq = 'S'
      WHERE item_id = r_item.item_id;
    END IF;
    --
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF v_aprov_final = 1
  THEN
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            v_cliente_id,
                            'OPCIONAL',
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   it_controle_pkg.integrar('JOB_APROV_ORCAM_ENVIAR',
                            p_empresa_id,
                            v_job_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   it_controle_pkg.integrar('ORCAMENTO_ATUALIZAR',
                            p_empresa_id,
                            p_orcamento_id,
                            NULL,
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
  IF v_aprov_final = 1
  THEN
   orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
  IF v_aprov_final = 1
  THEN
   v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
   v_compl_histor   := 'Aprovadores: ' || nvl(v_aprovadores, '-');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORCAMENTO',
                    'APROVAR',
                    v_identif_objeto,
                    p_orcamento_id,
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
 END; -- aprovar
 --
 --
 PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/07/2015
  -- DESCRICAO: Marca o ORCAMENTO como reprovado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/06/2022  Grava reprovacao em orcam_fluxo_aprov
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_compl_reprov      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_num_orcamento   orcamento.num_orcamento%TYPE;
  v_status_orcam    orcamento.status%TYPE;
  v_seq_aprov       orcam_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_maior orcam_fluxo_aprov.seq_aprov%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_job_id          job.job_id%TYPE;
  v_papel_id        papel.papel_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
  CURSOR c_item IS
   SELECT item_id,
          natureza_item
     FROM item
    WHERE orcamento_id = p_orcamento_id;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_AP',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam <> 'EMAPRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_reprov) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo_reprov)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_reprov)) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_fluxo_aprov
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt > 0
  THEN
   -- existe fluxo de aprovacao.
   -- assume que a aprovacao deve obedecer a sequencia.
   -- pega a maior sequencia ja aprovada.
   SELECT nvl(MAX(seq_aprov), 0)
     INTO v_seq_aprov_maior
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id
      AND data_status IS NOT NULL;
   --
   -- pega a proxima sequencia com aprovacao pendente
   SELECT nvl(MIN(seq_aprov), 0)
     INTO v_seq_aprov
     FROM orcam_fluxo_aprov
    WHERE orcamento_id = p_orcamento_id
      AND data_status IS NULL
      AND seq_aprov > v_seq_aprov_maior;
   --
   -- Verifica o papel do usuario que pode aprovar nessa sequencia.
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up
    WHERE up.usuario_id = p_usuario_sessao_id
      AND EXISTS (SELECT 1
             FROM papel_priv pp,
                  privilegio pr
            WHERE up.papel_id = pp.papel_id
              AND pp.privilegio_id = pr.privilegio_id
              AND pr.codigo = 'ORCAMENTO_AP')
      AND EXISTS (SELECT 1
             FROM orcam_fluxo_aprov oa
            WHERE oa.orcamento_id = p_orcamento_id
              AND oa.papel_id = up.papel_id
              AND oa.seq_aprov = v_seq_aprov
              AND oa.data_status IS NULL);
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não tem papel de aprovador para essa sequência ' || to_char(v_seq_aprov) || '.';
    RAISE v_exception;
   END IF;
   --
   UPDATE orcam_fluxo_aprov
      SET usuario_id  = p_usuario_sessao_id,
          status      = 'REPROV',
          data_status = SYSDATE,
          motivo      = TRIM(p_motivo_reprov),
          complemento = TRIM(p_compl_reprov)
    WHERE orcamento_id = p_orcamento_id
      AND papel_id = v_papel_id
      AND seq_aprov = v_seq_aprov;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'REPROV',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id,
         motivo_status     = TRIM(p_motivo_reprov),
         compl_status      = TRIM(p_compl_reprov)
   WHERE orcamento_id = p_orcamento_id;
  --
  -- gera historico dos itens
  FOR r_item IN c_item
  LOOP
   IF r_item.natureza_item = 'CUSTO'
   THEN
    item_pkg.historico_gerar(p_usuario_sessao_id,
                             r_item.item_id,
                             'REPROVACAO',
                             NULL,
                             p_erro_cod,
                             p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := TRIM(p_compl_reprov);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'REPROVAR',
                   v_identif_objeto,
                   p_orcamento_id,
                   v_compl_histor,
                   TRIM(p_motivo_reprov),
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
 END reprovar;
 --
 --
 PROCEDURE revisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 15/12/2006
  -- DESCRICAO: revisa um orcamento aprovado (volta para preparacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2015  Grava usuario que desaprovou
  -- Silvia            08/04/2020  Libera revisao com item faturado
  -- Rafael            15/05/2025  Nova tratativa criada para o novo privilégio  (ORCAMENTO_RPCF)
  -- Ana Luiza
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
  CURSOR c_item IS
   SELECT item_id,
          natureza_item
     FROM item
    WHERE orcamento_id = p_orcamento_id;
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  -- RP_150525 Se o checkin do orcamento estiverem pendente 
  IF orcamento_pkg.valor_checkin_pend_retornar(p_orcamento_id, 'T') <> 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_RP',
                                 NULL,
                                 p_orcamento_id,
                                 p_empresa_id) = 0 AND
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_RPCF',
                                 NULL,
                                 p_orcamento_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- RP_150525 Se o checkin do orcamento não estiver pendente 
  IF orcamento_pkg.valor_checkin_pend_retornar(p_orcamento_id, 'T') = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_RPCF',
                                 NULL,
                                 p_orcamento_id,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Este Orçamento não pode ser revisado pois já está fechado, e com todas as sobras indicadas. Para revisar é necessário ter o privilégio de revisar orçamentos fechados.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --RP_150525 Removido a trava que não deixa o usuário revisar o check-in se estiver aprovado
  /*IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;*/
  --RP_150525F
  --
  IF v_status_orcam <> 'APROV'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM item ie,
           item_nota it
     WHERE ie.orcamento_id = p_orcamento_id
       AND ie.item_id = it.item_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa Estimativa de Custos já tem itens associados a notas fiscais.';
       RAISE v_exception;
    END IF;
  */
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM item ie,
           item_fatur it,
           faturamento fa
     WHERE ie.orcamento_id = p_orcamento_id
       AND ie.item_id = it.item_id
       AND it.faturamento_id = fa.faturamento_id
       AND fa.flag_bv = 'N';
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa Estimativa de Custos já tem itens associados a ordens de faturamento.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_rev) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo_rev)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_rev)) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'PREP',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id,
         motivo_status     = TRIM(p_motivo_rev),
         compl_status      = TRIM(p_compl_rev)
   WHERE orcamento_id = p_orcamento_id;
  --
  -- gera historico dos itens
  FOR r_item IN c_item
  LOOP
   IF r_item.natureza_item = 'CUSTO'
   THEN
    item_pkg.historico_gerar(p_usuario_sessao_id,
                             r_item.item_id,
                             'REVISAO',
                             NULL,
                             p_erro_cod,
                             p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
  v_compl_histor   := TRIM(p_compl_rev);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'REVISAR',
                   v_identif_objeto,
                   p_orcamento_id,
                   v_compl_histor,
                   TRIM(p_motivo_rev),
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
 END revisar;
 --
 --
 PROCEDURE revisar_especial
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Volta o orcamento para preparacao (operacao especial).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2015  Grava usuario que alterou o status
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcamento     IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
  CURSOR c_item IS
   SELECT item_id,
          natureza_item
     FROM item
    WHERE orcamento_id = v_orcamento_id;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
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
  IF rtrim(p_num_orcamento) IS NULL OR inteiro_validar(p_num_orcamento) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da Estimativa de Custos inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(oc.orcamento_id)
    INTO v_orcamento_id
    FROM orcamento oc
   WHERE job_id = v_job_id
     AND num_orcamento = to_number(p_num_orcamento);
  --
  IF v_orcamento_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe nesse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = v_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam NOT IN ('APROV')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Estimativa de Custos não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE orcamento
     SET status            = 'PREP',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE orcamento_id = v_orcamento_id;
  --
  -- gera historico dos itens 
  FOR r_item IN c_item
  LOOP
   IF r_item.natureza_item = 'CUSTO'
   THEN
    item_pkg.historico_gerar(p_usuario_sessao_id,
                             r_item.item_id,
                             'REVISAO',
                             NULL,
                             p_erro_cod,
                             p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR_ESP1',
                   v_identif_objeto,
                   v_orcamento_id,
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
 END revisar_especial;
 --
 --
 PROCEDURE honorario_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Alteracao de honorarios de estimativa aprovada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/11/2014  Aumento de casas decimais do percentual (de 2 p/ 6).
  -- Silvia            14/09/2016  Naturezas de item configuraveis.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcamento     IN VARCHAR2,
  p_perc_honor        IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_orcamento_id     orcamento.orcamento_id%TYPE;
  v_num_orcamento    orcamento.num_orcamento%TYPE;
  v_status_orcam     orcamento.status%TYPE;
  v_perc_honor       NUMBER;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_job_id           job.job_id%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_natureza_item_id orcam_nitem_pdr.natureza_item_id%TYPE;
  v_nome_natureza    natureza_item.nome%TYPE;
  v_desc_calculo     VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
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
  IF rtrim(p_num_orcamento) IS NULL OR inteiro_validar(p_num_orcamento) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da Estimativa de Custos inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(oc.orcamento_id)
    INTO v_orcamento_id
    FROM orcamento oc
   WHERE job_id = v_job_id
     AND num_orcamento = to_number(p_num_orcamento);
  --
  IF v_orcamento_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe nesse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = v_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_orcam <> 'APROV'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não se encontra aprovada.';
   RAISE v_exception;
  END IF;
  --
  SELECT natureza_item_id,
         nome,
         util_pkg.desc_retornar('mod_calculo', mod_calculo)
    INTO v_natureza_item_id,
         v_nome_natureza,
         v_desc_calculo
    FROM natureza_item
   WHERE empresa_id = p_empresa_id
     AND codigo = 'HONOR';
  --
  IF rtrim(p_perc_honor) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_desc_calculo || ' para ' || v_nome_natureza ||
                 ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_honor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' || p_perc_honor || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_honor := nvl(numero_converter(p_perc_honor), 0);
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM orcam_nitem_pdr
   WHERE orcamento_id = v_orcamento_id
     AND natureza_item_id = v_natureza_item_id;
  --
  INSERT INTO orcam_nitem_pdr
   (orcamento_id,
    natureza_item_id,
    valor_padrao)
  VALUES
   (v_orcamento_id,
    v_natureza_item_id,
    v_perc_honor);
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, v_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR_ESP2',
                   v_identif_objeto,
                   v_orcamento_id,
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
 END; -- honorario_atualizar
 --
 --
 PROCEDURE item_transferir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Transferencia de item de uma estimativa para outra.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcam_de      IN VARCHAR2,
  p_num_item          IN VARCHAR2,
  p_num_orcam_para    IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_orcam_de_id    orcamento.orcamento_id%TYPE;
  v_orcam_para_id  orcamento.orcamento_id%TYPE;
  v_status_orcam   orcamento.status%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_item_id        item.item_id%TYPE;
  v_tipo_item      item.tipo_item%TYPE;
  v_grupo          item.grupo%TYPE;
  v_subgrupo       item.subgrupo%TYPE;
  v_ordem_grupo    item.ordem_grupo%TYPE;
  v_ordem_subgrupo item.ordem_subgrupo%TYPE;
  v_ordem_item     item.ordem_item%TYPE;
  v_nome_item      VARCHAR2(100);
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
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
  IF rtrim(p_num_orcam_de) IS NULL OR inteiro_validar(p_num_orcam_de) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da Estimativa de Custos origem inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_num_orcam_para) IS NULL OR inteiro_validar(p_num_orcam_para) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da Estimativa de Custos destino inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(oc.orcamento_id)
    INTO v_orcam_de_id
    FROM orcamento oc
   WHERE job_id = v_job_id
     AND num_orcamento = to_number(p_num_orcam_de);
  --
  IF v_orcam_de_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos de origem não existe nesse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(oc.orcamento_id)
    INTO v_orcam_para_id
    FROM orcamento oc
   WHERE job_id = v_job_id
     AND num_orcamento = to_number(p_num_orcam_para);
  --
  IF v_orcam_para_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos destino não existe nesse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_status_orcam
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = v_orcam_de_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_id)
    INTO v_item_id
    FROM item
   WHERE orcamento_id = v_orcam_de_id
     AND natureza_item = 'CUSTO'
     AND flag_sem_valor = 'N'
     AND tipo_item || to_char(num_seq) = upper(TRIM(p_num_item));
  --
  IF v_item_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe nessa Estimativa de Custos de origem.';
   RAISE v_exception;
  END IF;
  --
  SELECT it.tipo_item,
         it.grupo,
         it.subgrupo,
         substr(TRIM(tp.nome || '  ' || it.complemento), 1, 50)
    INTO v_tipo_item,
         v_grupo,
         v_subgrupo,
         v_nome_item
    FROM item         it,
         tipo_produto tp
   WHERE it.item_id = v_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- retorna a ordem do item COM quebra por tipo no orcamento destino
  item_pkg.ordem_retornar(p_usuario_sessao_id,
                          v_job_id,
                          v_orcam_para_id,
                          0,
                          v_tipo_item,
                          v_grupo,
                          v_subgrupo,
                          'S',
                          v_ordem_grupo,
                          v_ordem_subgrupo,
                          v_ordem_item,
                          p_erro_cod,
                          p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE item
     SET orcamento_id   = v_orcam_para_id,
         ordem_grupo    = v_ordem_grupo,
         ordem_subgrupo = v_ordem_subgrupo,
         ordem_item     = v_ordem_item
   WHERE item_id = v_item_id;
  --
  -- retorna a ordem do item SEM quebra por tipo no orcamento destino
  item_pkg.ordem_retornar(p_usuario_sessao_id,
                          v_job_id,
                          v_orcam_para_id,
                          0,
                          v_tipo_item,
                          v_grupo,
                          v_subgrupo,
                          'N',
                          v_ordem_grupo,
                          v_ordem_subgrupo,
                          v_ordem_item,
                          p_erro_cod,
                          p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE item
     SET orcamento_id      = v_orcam_para_id,
         ordem_grupo_sq    = v_ordem_grupo,
         ordem_subgrupo_sq = v_ordem_subgrupo,
         ordem_item_sq     = v_ordem_item
   WHERE item_id = v_item_id;
  --
  -- recalcula o numero sequencial dos itens do orcamento origem
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, v_orcam_de_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- recalcula o numero sequencial dos itens do orcamento destino
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, v_orcam_para_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- recalcula totais dos acessorios do orcamento origem
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcam_de_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- recalcula totais dos acessorios do orcamento destino
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcam_para_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- trata os status de check-in e faturamento do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, v_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := orcamento_pkg.numero_formatar(v_orcam_de_id);
  v_compl_histor   := 'Item transferido p/ a Estimativa de Custos ' || p_num_orcam_para || ': ' ||
                      upper(p_num_item) || '.' || v_nome_item;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR_ESP3',
                   v_identif_objeto,
                   v_orcam_de_id,
                   v_compl_histor,
                   p_justificativa,
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
 END; -- item_transferir
 --
 --
 PROCEDURE checkin_encerrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/03/2008
  -- DESCRICAO: Encerramento do checkin das estimativas, atraves do registro automatico
  --   de SOBRA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            08/01/2013  Encerramento como Sobra (SOB) ao inves de Servico nao 
  --                               Prestado (SNP).
  -- Silvia            03/04/2014  Encerramento como Sobra (SOB) para a parte sem abatimento 
  --                               e Servico nao Prestado (SNP) para a parte com abatimento.
  -- Silvia            28/05/2014  Verificacao de carta acordo pendente deixou de ser feita.
  -- Silvia            30/05/2014  Verificacao de itens de A deixou de ser feita.
  -- Silvia            20/09/2016  Naturezas de item configuraveis (ordenacao no cursor)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_orcamento_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_num_job            job.numero%TYPE;
  v_delimitador        CHAR(1);
  v_vetor_orcamento_id LONG;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_num_orcamento      orcamento.num_orcamento%TYPE;
  v_status             orcamento.status%TYPE;
  v_valor_pend         NUMBER;
  v_num_carta_acordo   carta_acordo.num_carta_acordo%TYPE;
  v_sobra_id           sobra.sobra_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_valor_abat_item    item_abat.valor_abat_item%TYPE;
  v_valor_sobra_item   item_sobra.valor_sobra_item%TYPE;
  v_flag_abate_fatur   item_sobra.flag_abate_fatur%TYPE;
  v_tipo_sobra         sobra.tipo_sobra%TYPE;
  v_xml_atual          CLOB;
  --
  CURSOR c_item IS
   SELECT it.item_id,
          item_pkg.valor_disponivel_retornar(it.item_id, 'APROVADO') valor_pend_it,
          it.tipo_item,
          it.natureza_item
     FROM item it
    WHERE it.orcamento_id = v_orcamento_id
      AND it.flag_sem_valor = 'N'
      AND it.natureza_item = 'CUSTO'
      AND it.tipo_item <> 'A'
      AND item_pkg.valor_disponivel_retornar(it.item_id, 'APROVADO') > 0
    ORDER BY ordem_grupo,
             ordem_subgrupo,
             ordem_item,
             tipo_item;
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
  -- privilegio do grupo JOBEND
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ORCAMENTO_CF', p_job_id, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero
    INTO v_num_job
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de orcamento
  ------------------------------------------------------------
  v_delimitador        := '|';
  v_vetor_orcamento_id := p_vetor_orcamento_id;
  --
  WHILE nvl(length(rtrim(v_vetor_orcamento_id)), 0) > 0
  LOOP
   v_orcamento_id := to_number(prox_valor_retornar(v_vetor_orcamento_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id
      AND job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa Estimativa de Custos não existe ou não pertence ao ' || v_lbl_job || ' (' ||
                  to_char(v_orcamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT num_orcamento,
          status,
          orcamento_pkg.valor_geral_pend_retornar(orcamento_id, 'T')
     INTO v_num_orcamento,
          v_status,
          v_valor_pend
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
   --
   IF v_status <> 'APROV'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Estimativa de Custos ' || to_char(v_num_orcamento) ||
                  ' não se encontra aprovada.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_pend = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Estimativa de Custos ' || to_char(v_num_orcamento) ||
                  ' não tem valor pendente.';
    RAISE v_exception;
   END IF;
   /*
   --
   -- verifica se existe alguma carta acordo pendente associada a essa estimativa.
   SELECT MIN(ca.num_carta_acordo)
     INTO v_num_carta_acordo
     FROM carta_acordo ca
    WHERE ca.job_id = p_job_id
      AND carta_acordo_pkg.valor_retornar(ca.carta_acordo_id,'SEM_NF') > 0
      AND EXISTS (SELECT 1
                    FROM item_carta ic,
                         item it
                   WHERE ic.carta_acordo_id = ca.carta_acordo_id
                     AND ic.item_id = it.item_id
                     AND it.orcamento_id = v_orcamento_id);
   --
   IF v_num_carta_acordo IS NOT NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A Estimativa de Custos ' || TO_CHAR(v_num_orcamento)  || 
                    ' tem cartas acordo ainda pendentes (CA: ' ||
                    TRIM(TO_CHAR(v_num_carta_acordo,'0000')) || ').';
      RAISE v_exception;
   END IF;
   */
   --
   -- loop por item com valor pendente da estimativa
   FOR r_item IN c_item
   LOOP
    IF r_item.tipo_item = 'A'
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens do tipo A com pendência devem ser encerrados individualmente (Estimativa de Custos: ' ||
                   to_char(v_num_orcamento) || ').';
     RAISE v_exception;
    END IF;
    --
    -- verifica se o item tem abatimentos soltos
    SELECT nvl(SUM(valor_abat_item), 0)
      INTO v_valor_abat_item
      FROM item_abat  ia,
           abatimento ab
     WHERE ia.item_id = r_item.item_id
       AND ia.abatimento_id = ab.abatimento_id
       AND ab.carta_acordo_id IS NULL
       AND ab.sobra_id IS NULL;
    --
    IF v_valor_abat_item = 0
    THEN
     -- nao tem abatimento. Eh sobra
     v_tipo_sobra       := 'SOB';
     v_flag_abate_fatur := 'N';
     v_valor_sobra_item := r_item.valor_pend_it;
    ELSIF v_valor_abat_item >= r_item.valor_pend_it
    THEN
     -- valor restante integral foi abatido. Nao eh sobra
     v_tipo_sobra       := 'SNP';
     v_flag_abate_fatur := 'S';
     v_valor_sobra_item := r_item.valor_pend_it;
    ELSE
     -- a sobra precisa ser quebrada em duas. 
     -- o valor abatido fica como SNP 
     v_tipo_sobra       := 'SNP';
     v_flag_abate_fatur := 'S';
     v_valor_sobra_item := v_valor_abat_item;
     --
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
       valor_cred_cliente)
     VALUES
      (v_sobra_id,
       p_job_id,
       NULL,
       p_usuario_sessao_id,
       SYSDATE,
       v_tipo_sobra,
       'Encerramento do check-in',
       v_valor_sobra_item,
       0);
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
       r_item.item_id,
       v_sobra_id,
       v_valor_sobra_item,
       0,
       v_flag_abate_fatur);
     --
     -- o valor restante fica como SOBRA
     v_tipo_sobra       := 'SOB';
     v_flag_abate_fatur := 'N';
     v_valor_sobra_item := r_item.valor_pend_it - v_valor_abat_item;
     --
    END IF;
    --
    --
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
      valor_cred_cliente)
    VALUES
     (v_sobra_id,
      p_job_id,
      NULL,
      p_usuario_sessao_id,
      SYSDATE,
      v_tipo_sobra,
      'Encerramento do check-in',
      v_valor_sobra_item,
      0);
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
      r_item.item_id,
      v_sobra_id,
      v_valor_sobra_item,
      0,
      v_flag_abate_fatur);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, r_item.item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
   --
   ------------------------------------------------------------
   -- gera xml do log 
   ------------------------------------------------------------
   orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
   v_compl_histor   := 'Encerramento de check-in';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORCAMENTO',
                    'ALTERAR',
                    v_identif_objeto,
                    v_orcamento_id,
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
  END LOOP;
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
 END; -- checkin_encerrar
 --
 --
 PROCEDURE faturamento_encerrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/03/2008
  -- DESCRICAO: Encerramento do faturamento das estimativas, atraves do registro automatico
  --   de ABATIMENTO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            20/09/2016  Naturezas de item configuraveis (ordenacao no cursor)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_orcamento_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_num_job            job.numero%TYPE;
  v_delimitador        CHAR(1);
  v_vetor_orcamento_id LONG;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_num_orcamento      orcamento.num_orcamento%TYPE;
  v_status             orcamento.status%TYPE;
  v_valor_pend         NUMBER;
  v_abatimento_id      abatimento.abatimento_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  --
  CURSOR c_item IS
   SELECT it.item_id,
          faturamento_pkg.valor_retornar(it.item_id, 0, 'AFATURAR') valor_pend_it,
          it.tipo_item,
          it.natureza_item
     FROM item it
    WHERE it.orcamento_id = v_orcamento_id
      AND it.flag_sem_valor = 'N'
      AND faturamento_pkg.valor_retornar(it.item_id, 0, 'AFATURAR') > 0
    ORDER BY ordem_grupo,
             ordem_subgrupo,
             ordem_item,
             tipo_item;
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
  -- privilegio do grupo JOBEND
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ORCAMENTO_FF', p_job_id, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero
    INTO v_num_job
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de orcamento
  ------------------------------------------------------------
  v_delimitador        := '|';
  v_vetor_orcamento_id := p_vetor_orcamento_id;
  --
  WHILE nvl(length(rtrim(v_vetor_orcamento_id)), 0) > 0
  LOOP
   v_orcamento_id := to_number(prox_valor_retornar(v_vetor_orcamento_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id
      AND job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa Estimativa de Custos não existe ou não pertence ao ' || v_lbl_job || ' (' ||
                  to_char(v_orcamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT num_orcamento,
          status,
          faturamento_pkg.valor_orcam_retornar(orcamento_id, 'AFATURAR')
     INTO v_num_orcamento,
          v_status,
          v_valor_pend
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
   --
   IF v_status <> 'APROV'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Estimativa de Custos ' || to_char(v_num_orcamento) ||
                  ' não se encontra aprovada.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_pend = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Estimativa de Custos ' || to_char(v_num_orcamento) ||
                  ' não tem valor pendente.';
    RAISE v_exception;
   END IF;
   --
   -- loop por item com valor pendente da estimativa
   FOR r_item IN c_item
   LOOP
    IF r_item.tipo_item = 'A' AND r_item.natureza_item = 'CUSTO'
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens do tipo A com pendência devem ser encerrados individualmente (Estimativa de Custos: ' ||
                   to_char(v_num_orcamento) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT seq_abatimento.nextval
      INTO v_abatimento_id
      FROM dual;
    --
    INSERT INTO abatimento
     (abatimento_id,
      job_id,
      usuario_resp_id,
      data_entrada,
      flag_debito_cli,
      justificativa,
      valor_abat)
    VALUES
     (v_abatimento_id,
      p_job_id,
      p_usuario_sessao_id,
      SYSDATE,
      'N',
      'Encerramento do faturamento',
      r_item.valor_pend_it);
    --
    INSERT INTO item_abat
     (item_abat_id,
      item_id,
      abatimento_id,
      valor_abat_item)
    VALUES
     (seq_item_abat.nextval,
      r_item.item_id,
      v_abatimento_id,
      r_item.valor_pend_it);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, r_item.item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
   --
   ------------------------------------------------------------
   -- gera xml do log 
   ------------------------------------------------------------
   orcamento_pkg.xml_gerar(v_orcamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
   v_compl_histor   := 'Encerramento de faturamento';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORCAMENTO',
                    'ALTERAR',
                    v_identif_objeto,
                    v_orcamento_id,
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
  END LOOP;
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
 END; -- faturamento_encerrar
 --
 --
 PROCEDURE task_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/08/2006
  -- DESCRICAO: Gera tasks de notificacao de orcamento relacionadas a um determinado
  --    orcamento. O parametro p_objeto_id corresponde ao orcamento_id.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_objeto_id         IN NUMBER,
  p_tipo_task         IN VARCHAR2,
  p_prioridade        IN task.prioridade%TYPE,
  p_vetor_papel_id    IN LONG,
  p_obs               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_papel_id       papel.papel_id%TYPE;
  v_delimitador    CHAR(1);
  v_vetor_papel_id LONG;
  v_task_id        task.task_id%TYPE;
  v_tipo_objeto_id task.tipo_objeto_id%TYPE;
  v_usuario        pessoa.apelido%TYPE;
  v_desc_curta     task.desc_curta%TYPE;
  v_desc_detalhada task.desc_detalhada%TYPE;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
  IF p_tipo_task NOT IN ('ORCAM_PRONTO_MSG', 'ORCAM_APROVADO_MSG') OR rtrim(p_tipo_task) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de task inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_objeto_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.job_id,
         o.num_orcamento,
         o.orcamento_id
    INTO v_job_id,
         v_num_orcamento,
         v_orcamento_id
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_objeto_id
     AND o.job_id = j.job_id;
  --
  SELECT j.numero,
         j.status
    INTO v_numero_job,
         v_status_job
    FROM job j
   WHERE j.job_id = v_job_id;
  --
  IF p_flag_commit = 'S'
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_A',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_objeto_id)
    INTO v_tipo_objeto_id
    FROM tipo_objeto
   WHERE codigo = 'ORCAMENTO';
  --
  IF v_tipo_objeto_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe tipo de objeto criado para orçamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_obs) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_vetor_papel_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário indicar pelo menos um papel como responsável pela task.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_tipo_task = 'ORCAM_PRONTO_MSG'
  THEN
   v_desc_curta     := 'Estimativa de Custos Pronta';
   v_desc_detalhada := rtrim(v_usuario || ' solicitou que tome conhecimento ' ||
                             'de Estimativa de Custos Pronta (Número: ' || to_char(v_num_orcamento) ||
                             '). ' || p_obs);
  END IF;
  --
  IF p_tipo_task = 'ORCAM_APROVADO_MSG'
  THEN
   v_desc_curta     := 'Estimativa de Custos Aprovada';
   v_desc_detalhada := rtrim(v_usuario || ' solicitou que tome conhecimento ' ||
                             'de Estimativa de Custos Aprovada (Número: ' ||
                             to_char(v_num_orcamento) || '). ' || p_obs);
  END IF;
  --
  v_delimitador    := ',';
  v_vetor_papel_id := p_vetor_papel_id;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0
  LOOP
   v_papel_id := to_number(prox_valor_retornar(v_vetor_papel_id, v_delimitador));
   --
   task_pkg.adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      'N', -- flag_commit
                      v_job_id,
                      0, -- milestone_id
                      v_papel_id,
                      v_desc_curta,
                      v_desc_detalhada,
                      p_prioridade,
                      p_tipo_task,
                      v_task_id, -- output
                      p_erro_cod,
                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- vincula o orcamento a essa task
   UPDATE task
      SET objeto_id      = v_orcamento_id,
          tipo_objeto_id = v_tipo_objeto_id
    WHERE task_id = v_task_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF p_tipo_task = 'ORCAM_PRONTO_MSG'
  THEN
   v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
   v_compl_histor   := 'Geração de tasks (orçamento pronto)';
  ELSE
   v_identif_objeto := orcamento_pkg.numero_formatar(v_orcamento_id);
   v_compl_histor   := 'Geração de tasks (orçamento aprovado)';
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_orcamento_id,
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
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
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
 END; -- task_gerar
 --
 --
 PROCEDURE grupo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 22/12/2006
  -- DESCRICAO: atualiza o nome de um determinado grupo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo_old         IN item.grupo%TYPE,
  p_grupo_new         IN item.grupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_status_job job.status%TYPE;
  v_job_id     job.job_id%TYPE;
  v_exception  EXCEPTION;
  v_lbl_job    VARCHAR2(100);
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.status,
         j.job_id
    INTO v_status_job,
         v_job_id
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_quebra_tipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag quebra por tipo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'S' AND TRIM(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'N' AND TRIM(p_tipo_item) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item não deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_grupo_old) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo a ser atualizado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_grupo_new) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O novo nome do grupo deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  -- COM quebra por tipo
  IF p_flag_quebra_tipo = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo_old);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo_new);
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse novo nome de grupo já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- SEM quebra por tipo
  IF p_flag_quebra_tipo = 'N'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo_old);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo_new);
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse novo nome de grupo já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'S'
  THEN
   UPDATE item
      SET grupo = p_grupo_new
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo_old);
  ELSE
   UPDATE item
      SET grupo = p_grupo_new
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo_old);
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
 END; -- grupo_atualizar
 --
 --
 PROCEDURE subgrupo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 22/12/2006
  -- DESCRICAO: atualiza o nome de um determinado subgrupo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo_old      IN item.subgrupo%TYPE,
  p_subgrupo_new      IN item.subgrupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_status_job job.status%TYPE;
  v_job_id     job.job_id%TYPE;
  v_exception  EXCEPTION;
  v_lbl_job    VARCHAR2(100);
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.status,
         j.job_id
    INTO v_status_job,
         v_job_id
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_quebra_tipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag quebra por tipo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'S' AND TRIM(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'N' AND TRIM(p_tipo_item) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item não deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_grupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_subgrupo_old) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do subgrupo a ser atualizado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_subgrupo_new) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O novo nome do subgrupo deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  -- COM quebra por tipo
  IF p_flag_quebra_tipo = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_old);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse subgrupo não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_new);
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse novo nome de subgrupo já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- SEM quebra por tipo
  IF p_flag_quebra_tipo = 'N'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_old);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse subgrupo não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_new);
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse novo nome de subgrupo já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'S'
  THEN
   UPDATE item
      SET subgrupo = p_subgrupo_new
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_old);
  ELSE
   UPDATE item
      SET subgrupo = p_subgrupo_new
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo_old);
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
 END; -- subgrupo_atualizar
 --
 --
 PROCEDURE grupo_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 22/12/2006
  -- DESCRICAO: Movimentacao de GRUPO, de acordo com a direcao informada.
  --   (p_direcao: S - sobe, D - desce).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt          INTEGER;
  v_ordem_ori   NUMBER(5);
  v_ordem_aux   NUMBER(5);
  v_status_job  job.status%TYPE;
  v_job_id      job.job_id%TYPE;
  v_grupo_troca item.grupo%TYPE;
  v_exception   EXCEPTION;
  v_lbl_job     VARCHAR2(100);
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.status
    INTO v_status_job
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(p_orcamento_id) > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O grupo não pode ser movido ' ||
                 'pois essa Estimativa de Custos já foi aprovada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_direcao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da direção é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('S', 'D')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção inválida.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_grupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_quebra_tipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag quebra por tipo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'S' AND TRIM(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'N' AND TRIM(p_tipo_item) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item não deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para COM quebra por tipo
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'S'
  THEN
   -- seleciona a ordem original
   SELECT MAX(ordem_grupo)
     INTO v_ordem_ori
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo);
   --
   IF v_ordem_ori IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo não pertence a essa Estimativa de Custos.';
    RAISE v_exception;
   END IF;
   --
   IF p_direcao = 'D'
   THEN
    -- desce uma posicao.
    -- procura o proximo registro para fazer a troca.
    SELECT MIN(ordem_grupo)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND ordem_grupo > v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o proximo registro. Faz a troca
     SELECT MAX(grupo)
       INTO v_grupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND ordem_grupo = v_ordem_aux;
     --
     UPDATE item
        SET ordem_grupo = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo);
     --
     UPDATE item
        SET ordem_grupo = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = v_grupo_troca;
    ELSE
     -- nao achou o proximo registro (ja esta no fim).
     -- passa para o comeco, desde que nao seja o unico registro.
     SELECT MIN(ordem_grupo)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND ordem_grupo > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux - 1;
      --
      UPDATE item
         SET ordem_grupo = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND tipo_item = p_tipo_item
         AND grupo = TRIM(p_grupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'D'
   --
   IF p_direcao = 'S'
   THEN
    -- sobe uma posicao.
    -- procura o registro anterior para fazer a troca.
    SELECT MAX(ordem_grupo)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND ordem_grupo > 0
       AND ordem_grupo < v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o registro anterior. Faz a troca
     SELECT MAX(grupo)
       INTO v_grupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND ordem_grupo = v_ordem_aux;
     --
     UPDATE item
        SET ordem_grupo = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo);
     --
     UPDATE item
        SET ordem_grupo = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = v_grupo_troca;
    ELSE
     -- nao achou o registro anterior (ja esta no comeco).
     -- passa para o fim, desde que nao seja o unico registro.
     SELECT MAX(ordem_grupo)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND ordem_grupo > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux + 1;
      --
      UPDATE item
         SET ordem_grupo = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND tipo_item = p_tipo_item
         AND grupo = TRIM(p_grupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'S'
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para SEM quebra por tipo
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'N'
  THEN
   -- seleciona a ordem original
   SELECT MAX(ordem_grupo_sq)
     INTO v_ordem_ori
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo);
   --
   IF v_ordem_ori IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse grupo não pertence a essa Estimativa de Custos.';
    RAISE v_exception;
   END IF;
   --
   IF p_direcao = 'D'
   THEN
    -- desce uma posicao.
    -- procura o proximo registro para fazer a troca.
    SELECT MIN(ordem_grupo_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND ordem_grupo_sq > v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o proximo registro. Faz a troca
     SELECT MAX(grupo)
       INTO v_grupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND ordem_grupo_sq = v_ordem_aux;
     --
     UPDATE item
        SET ordem_grupo_sq = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo);
     --
     UPDATE item
        SET ordem_grupo_sq = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND grupo = v_grupo_troca;
    ELSE
     -- nao achou o proximo registro (ja esta no fim).
     -- passa para o comeco, desde que nao seja o unico registro.
     SELECT MIN(ordem_grupo_sq)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND ordem_grupo_sq > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux - 1;
      --
      UPDATE item
         SET ordem_grupo_sq = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND grupo = TRIM(p_grupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'D'
   --
   IF p_direcao = 'S'
   THEN
    -- sobe uma posicao.
    -- procura o registro anterior para fazer a troca.
    SELECT MAX(ordem_grupo_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND ordem_grupo_sq > 0
       AND ordem_grupo_sq < v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o registro anterior. Faz a troca
     SELECT MAX(grupo)
       INTO v_grupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND ordem_grupo_sq = v_ordem_aux;
     --
     UPDATE item
        SET ordem_grupo_sq = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo);
     --
     UPDATE item
        SET ordem_grupo_sq = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND grupo = v_grupo_troca;
    ELSE
     -- nao achou o registro anterior (ja esta no comeco).
     -- passa para o fim, desde que nao seja o unico registro.
     SELECT MAX(ordem_grupo_sq)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND ordem_grupo_sq > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux + 1;
      --
      UPDATE item
         SET ordem_grupo_sq = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND grupo = TRIM(p_grupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'S'
  END IF;
  --
  ------------------------------------------------------------
  -- recalcula o numero sequencial dos itens do orcamento
  ------------------------------------------------------------
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
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
 END; -- grupo_mover
 --
 --
 PROCEDURE subgrupo_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 22/12/2006
  -- DESCRICAO: Movimentacao de SUBGRUPO, de acordo com a direcao informada.
  --   (p_direcao: S - sobe, D - desce).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo          IN item.subgrupo%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_ordem_ori      NUMBER(5);
  v_ordem_aux      NUMBER(5);
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_subgrupo_troca item.subgrupo%TYPE;
  v_exception      EXCEPTION;
  v_lbl_job        VARCHAR2(100);
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
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.status
    INTO v_status_job
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(p_orcamento_id) > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O subgrupo não pode ser movido ' ||
                 'pois essa Estimativa de Custos já foi aprovada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_direcao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da direção é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('S', 'D')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção inválida.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_grupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_subgrupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do subgrupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_quebra_tipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag quebra por tipo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'S' AND TRIM(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_quebra_tipo = 'N' AND TRIM(p_tipo_item) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do item não deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para COM quebra por tipo
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'S'
  THEN
   -- seleciona a ordem original
   SELECT MAX(ordem_subgrupo)
     INTO v_ordem_ori
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo);
   --
   IF v_ordem_ori IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse subgrupo não pertence a essa Estimativa de Custos.';
    RAISE v_exception;
   END IF;
   --
   IF p_direcao = 'D'
   THEN
    -- desce uma posicao.
    -- procura o proximo registro para fazer a troca.
    SELECT MIN(ordem_subgrupo)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND grupo = TRIM(p_grupo)
       AND ordem_subgrupo > v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o proximo registro. Faz a troca
     SELECT MAX(subgrupo)
       INTO v_subgrupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo = v_ordem_aux;
     --
     UPDATE item
        SET ordem_subgrupo = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND subgrupo = TRIM(p_subgrupo);
     --
     UPDATE item
        SET ordem_subgrupo = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND subgrupo = v_subgrupo_troca;
    ELSE
     -- nao achou o proximo registro (ja esta no fim).
     -- passa para o comeco, desde que nao seja o unico registro.
     SELECT MIN(ordem_subgrupo)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux - 1;
      --
      UPDATE item
         SET ordem_subgrupo = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND tipo_item = p_tipo_item
         AND grupo = TRIM(p_grupo)
         AND subgrupo = TRIM(p_subgrupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'D'
   --
   IF p_direcao = 'S'
   THEN
    -- sobe uma posicao.
    -- procura o registro anterior para fazer a troca.
    SELECT MAX(ordem_subgrupo)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND grupo = TRIM(p_grupo)
       AND ordem_subgrupo > 0
       AND ordem_subgrupo < v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o registro anterior. Faz a troca
     SELECT MAX(subgrupo)
       INTO v_subgrupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo = v_ordem_aux;
     --
     UPDATE item
        SET ordem_subgrupo = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND subgrupo = TRIM(p_subgrupo);
     --
     UPDATE item
        SET ordem_subgrupo = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND subgrupo = v_subgrupo_troca;
    ELSE
     -- nao achou o registro anterior (ja esta no comeco).
     -- passa para o fim, desde que nao seja o unico registro.
     SELECT MAX(ordem_subgrupo)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND tipo_item = p_tipo_item
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux + 1;
      --
      UPDATE item
         SET ordem_subgrupo = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND tipo_item = p_tipo_item
         AND grupo = TRIM(p_grupo)
         AND subgrupo = TRIM(p_subgrupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'S'
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para SEM quebra por tipo
  ------------------------------------------------------------
  IF p_flag_quebra_tipo = 'N'
  THEN
   -- seleciona a ordem original
   SELECT MAX(ordem_subgrupo_sq)
     INTO v_ordem_ori
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND grupo = TRIM(p_grupo)
      AND subgrupo = TRIM(p_subgrupo);
   --
   IF v_ordem_ori IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse subgrupo não pertence a essa Estimativa de Custos.';
    RAISE v_exception;
   END IF;
   --
   IF p_direcao = 'D'
   THEN
    -- desce uma posicao.
    -- procura o proximo registro para fazer a troca.
    SELECT MIN(ordem_subgrupo_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND grupo = TRIM(p_grupo)
       AND ordem_subgrupo_sq > v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o proximo registro. Faz a troca
     SELECT MAX(subgrupo)
       INTO v_subgrupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo_sq = v_ordem_aux;
     --
     UPDATE item
        SET ordem_subgrupo_sq = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND subgrupo = TRIM(p_subgrupo);
     --
     UPDATE item
        SET ordem_subgrupo_sq = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND subgrupo = v_subgrupo_troca;
    ELSE
     -- nao achou o proximo registro (ja esta no fim).
     -- passa para o comeco, desde que nao seja o unico registro.
     SELECT MIN(ordem_subgrupo_sq)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo_sq > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux - 1;
      --
      UPDATE item
         SET ordem_subgrupo_sq = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND grupo = TRIM(p_grupo)
         AND subgrupo = TRIM(p_subgrupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'D'
   --
   IF p_direcao = 'S'
   THEN
    -- sobe uma posicao.
    -- procura o registro anterior para fazer a troca.
    SELECT MAX(ordem_subgrupo_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND grupo = TRIM(p_grupo)
       AND ordem_subgrupo_sq > 0
       AND ordem_subgrupo_sq < v_ordem_ori;
    --
    IF v_ordem_aux IS NOT NULL
    THEN
     -- achou o registro anterior. Faz a troca
     SELECT MAX(subgrupo)
       INTO v_subgrupo_troca
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo_sq = v_ordem_aux;
     --
     UPDATE item
        SET ordem_subgrupo_sq = v_ordem_aux
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND subgrupo = TRIM(p_subgrupo);
     --
     UPDATE item
        SET ordem_subgrupo_sq = v_ordem_ori
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND subgrupo = v_subgrupo_troca;
    ELSE
     -- nao achou o registro anterior (ja esta no comeco).
     -- passa para o fim, desde que nao seja o unico registro.
     SELECT MAX(ordem_subgrupo_sq)
       INTO v_ordem_aux
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND grupo = TRIM(p_grupo)
        AND ordem_subgrupo_sq > 0;
     --
     IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
     THEN
      --
      v_ordem_aux := v_ordem_aux + 1;
      --
      UPDATE item
         SET ordem_subgrupo_sq = v_ordem_aux
       WHERE orcamento_id = p_orcamento_id
         AND grupo = TRIM(p_grupo)
         AND subgrupo = TRIM(p_subgrupo);
     END IF;
    END IF;
   END IF; -- fim do IF p_direcao = 'S'
  END IF;
  --
  ------------------------------------------------------------
  -- recalcula o numero sequencial dos itens do orcamento
  ------------------------------------------------------------
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
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
 END; -- subgrupo_mover
 --
 --
 PROCEDURE item_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 22/12/2006
  -- DESCRICAO: Movimentacao de ITEM, de acordo com a direcao informada.
  --   (p_direcao: S - sobe, D - desce).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_ordem_ori     NUMBER(5);
  v_ordem_ori_sq  NUMBER(5);
  v_ordem_aux     NUMBER(5);
  v_exception     EXCEPTION;
  v_job_id        job.job_id%TYPE;
  v_status_job    job.status%TYPE;
  v_orcamento_id  orcamento.orcamento_id%TYPE;
  v_grupo         item.grupo%TYPE;
  v_subgrupo      item.subgrupo%TYPE;
  v_item_troca_id item.item_id%TYPE;
  v_tipo_item     item.tipo_item%TYPE;
  v_lbl_job       VARCHAR2(100);
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
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT it.job_id,
         it.orcamento_id,
         it.grupo,
         it.subgrupo,
         jo.status,
         it.ordem_item,
         it.ordem_item_sq,
         it.tipo_item
    INTO v_job_id,
         v_orcamento_id,
         v_grupo,
         v_subgrupo,
         v_status_job,
         v_ordem_ori,
         v_ordem_ori_sq,
         v_tipo_item
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(v_orcamento_id) > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O item não pode ser movido ' || 'pois essa Estimativa de Custos já foi aprovada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_direcao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da direção é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('S', 'D')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_quebra_tipo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag quebra por tipo inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para COM quebra por tipo
  ------------------------------------------------------------
  IF p_direcao = 'D' AND p_flag_quebra_tipo = 'S'
  THEN
   -- desce uma posicao.
   -- procura o proximo registro para fazer a troca.
   SELECT MIN(ordem_item)
     INTO v_ordem_aux
     FROM item
    WHERE orcamento_id = v_orcamento_id
      AND natureza_item = 'CUSTO'
      AND tipo_item = v_tipo_item
      AND nvl(grupo, '0') = nvl(v_grupo, '0')
      AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
      AND ordem_item > v_ordem_ori;
   --
   IF v_ordem_aux IS NOT NULL
   THEN
    -- achou o proximo registro. Faz a troca
    SELECT MAX(item_id)
      INTO v_item_troca_id
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = v_tipo_item
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item = v_ordem_aux;
    --
    UPDATE item
       SET ordem_item = v_ordem_aux
     WHERE item_id = p_item_id;
    --
    UPDATE item
       SET ordem_item = v_ordem_ori
     WHERE item_id = v_item_troca_id;
   ELSE
    -- nao achou o proximo registro (ja esta no fim).
    -- passa para o comeco, desde que nao seja o unico registro.
    SELECT MIN(ordem_item)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = v_tipo_item
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item > 0;
    --
    IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
    THEN
     --
     v_ordem_aux := v_ordem_aux - 1;
     --
     UPDATE item
        SET ordem_item = v_ordem_aux
      WHERE item_id = p_item_id;
    END IF;
   END IF;
  END IF; -- fim do IF p_direcao = 'D'
  --
  IF p_direcao = 'S' AND p_flag_quebra_tipo = 'S'
  THEN
   -- sobe uma posicao.
   -- procura o registro anterior para fazer a troca.
   SELECT MAX(ordem_item)
     INTO v_ordem_aux
     FROM item
    WHERE orcamento_id = v_orcamento_id
      AND natureza_item = 'CUSTO'
      AND tipo_item = v_tipo_item
      AND nvl(grupo, '0') = nvl(v_grupo, '0')
      AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
      AND ordem_item < v_ordem_ori;
   --
   IF v_ordem_aux IS NOT NULL
   THEN
    -- achou o registro anterior. Faz a troca
    SELECT MAX(item_id)
      INTO v_item_troca_id
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = v_tipo_item
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item = v_ordem_aux;
    --
    UPDATE item
       SET ordem_item = v_ordem_aux
     WHERE item_id = p_item_id;
    --
    UPDATE item
       SET ordem_item = v_ordem_ori
     WHERE item_id = v_item_troca_id;
   ELSE
    -- nao achou o registro anterior (ja esta no comeco).
    -- passa para o fim, desde que nao seja o unico registro.
    SELECT MAX(ordem_item)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = v_tipo_item
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item > 0;
    --
    IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori
    THEN
     --
     v_ordem_aux := v_ordem_aux + 1;
     --
     UPDATE item
        SET ordem_item = v_ordem_aux
      WHERE item_id = p_item_id;
    END IF;
   END IF;
  END IF; -- fim do IF p_direcao = 'S'
  --
  ------------------------------------------------------------
  -- atualizacao do banco para SEM quebra por tipo
  ------------------------------------------------------------
  IF p_direcao = 'D' AND p_flag_quebra_tipo = 'N'
  THEN
   -- desce uma posicao.
   -- procura o proximo registro para fazer a troca.
   SELECT MIN(ordem_item_sq)
     INTO v_ordem_aux
     FROM item
    WHERE orcamento_id = v_orcamento_id
      AND natureza_item = 'CUSTO'
      AND nvl(grupo, '0') = nvl(v_grupo, '0')
      AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
      AND ordem_item_sq > v_ordem_ori_sq;
   --
   IF v_ordem_aux IS NOT NULL
   THEN
    -- achou o proximo registro. Faz a troca
    SELECT MAX(item_id)
      INTO v_item_troca_id
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item_sq = v_ordem_aux;
    --
    UPDATE item
       SET ordem_item_sq = v_ordem_aux
     WHERE item_id = p_item_id;
    --
    UPDATE item
       SET ordem_item_sq = v_ordem_ori_sq
     WHERE item_id = v_item_troca_id;
   ELSE
    -- nao achou o proximo registro (ja esta no fim).
    -- passa para o comeco, desde que nao seja o unico registro.
    SELECT MIN(ordem_item_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item_sq > 0;
    --
    IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori_sq
    THEN
     --
     v_ordem_aux := v_ordem_aux - 1;
     --
     UPDATE item
        SET ordem_item_sq = v_ordem_aux
      WHERE item_id = p_item_id;
    END IF;
   END IF;
  END IF; -- fim do IF p_direcao = 'D'
  --
  IF p_direcao = 'S' AND p_flag_quebra_tipo = 'N'
  THEN
   -- sobe uma posicao.
   -- procura o registro anterior para fazer a troca.
   SELECT MAX(ordem_item_sq)
     INTO v_ordem_aux
     FROM item
    WHERE orcamento_id = v_orcamento_id
      AND natureza_item = 'CUSTO'
      AND nvl(grupo, '0') = nvl(v_grupo, '0')
      AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
      AND ordem_item_sq < v_ordem_ori_sq;
   --
   IF v_ordem_aux IS NOT NULL
   THEN
    -- achou o registro anterior. Faz a troca
    SELECT MAX(item_id)
      INTO v_item_troca_id
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item_sq = v_ordem_aux;
    --
    UPDATE item
       SET ordem_item_sq = v_ordem_aux
     WHERE item_id = p_item_id;
    --
    UPDATE item
       SET ordem_item_sq = v_ordem_ori_sq
     WHERE item_id = v_item_troca_id;
   ELSE
    -- nao achou o registro anterior (ja esta no comeco).
    -- passa para o fim, desde que nao seja o unico registro.
    SELECT MAX(ordem_item_sq)
      INTO v_ordem_aux
      FROM item
     WHERE orcamento_id = v_orcamento_id
       AND natureza_item = 'CUSTO'
       AND nvl(grupo, '0') = nvl(v_grupo, '0')
       AND nvl(subgrupo, '0') = nvl(v_subgrupo, '0')
       AND ordem_item_sq > 0;
    --
    IF v_ordem_aux IS NOT NULL AND v_ordem_aux <> v_ordem_ori_sq
    THEN
     --
     v_ordem_aux := v_ordem_aux + 1;
     --
     UPDATE item
        SET ordem_item_sq = v_ordem_aux
      WHERE item_id = p_item_id;
    END IF;
   END IF;
  END IF; -- fim do IF p_direcao = 'S'
  --
  ------------------------------------------------------------
  -- recalcula o numero sequencial dos itens do orcamento
  ------------------------------------------------------------
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
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
 END; -- item_mover
 --
 --
 PROCEDURE num_seq_recalcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Recalcula o numero de sequencia dos itens de um determinado orcamento.
  --   Cada bloco correspondente aos tipos de item (A, B, C) tem sua propria numeracao,
  --   que é visualizada nas interfaces de check-in das notas fiscais.
  --      NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/11/2015  Pula itens ja aprovados (com sequencia salva).
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_tipo_item_ant item.tipo_item%TYPE;
  v_num_seq       item.num_seq%TYPE;
  v_exception     EXCEPTION;
  --
  -- cursor de itens sem numeracao salva
  CURSOR c_item IS
   SELECT item_id,
          tipo_item,
          num_seq
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND natureza_item = 'CUSTO'
      AND flag_sem_valor = 'N'
      AND flag_mantem_seq = 'N'
    ORDER BY tipo_item,
             ordem_grupo,
             ordem_subgrupo,
             ordem_item,
             item_id
      FOR UPDATE OF num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_tipo_item_ant := 'X';
  v_num_seq       := 0;
  --
  FOR r_item IN c_item
  LOOP
   IF v_tipo_item_ant <> r_item.tipo_item
   THEN
    -- quebrou o modalidade de contratação.
    -- procura a maior sequencia ja salva/usada
    SELECT nvl(MAX(num_seq), 0)
      INTO v_num_seq
      FROM item
     WHERE tipo_item = r_item.tipo_item
       AND orcamento_id = p_orcamento_id
       AND natureza_item = 'CUSTO'
       AND flag_sem_valor = 'N'
       AND flag_mantem_seq = 'S';
    --
    v_tipo_item_ant := r_item.tipo_item;
   END IF;
   --
   v_num_seq := v_num_seq + 1;
   --
   UPDATE item
      SET num_seq = v_num_seq
    WHERE item_id = r_item.item_id;
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
 END; -- num_seq_recalcular
 --
 --
 PROCEDURE totais_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 30/09/2016
  -- DESCRICAO: Gera linhas de totais do orcamento e instancia naturezas dos itens (copia 
  --  indices do job).
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_empresa_id      job.empresa_id%TYPE;
  v_job_id          job.job_id%TYPE;
  v_ordem_item      item.ordem_item%TYPE;
  v_tipo_produto_id tipo_produto.tipo_produto_id%TYPE;
  v_cod_produto     tipo_produto.codigo%TYPE;
  --
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          na.flag_sistema,
          na.flag_inc_a,
          na.flag_inc_b,
          na.flag_inc_c,
          jn.valor_padrao,
          na.ordem
     FROM job_nitem_pdr jn,
          natureza_item na
    WHERE na.natureza_item_id = jn.natureza_item_id
      AND jn.job_id = v_job_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.empresa_id,
         jo.job_id
    INTO v_empresa_id,
         v_job_id
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  ------------------------------------------------------------
  -- loop por natureza do item instanciada no job
  ------------------------------------------------------------
  v_ordem_item := 90000;
  --
  FOR r_na IN c_na
  LOOP
   -- copia indices do job
   INSERT INTO orcam_nitem_pdr
    (orcamento_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (p_orcamento_id,
     r_na.natureza_item_id,
     nvl(r_na.valor_padrao, 0));
   --
   -----------------------------------------
   -- criacao das linhas de totais
   -----------------------------------------
   IF r_na.flag_sistema = 'S'
   THEN
    -- natureza do sistema. 
    -- seleciona o tipo de produto correspondente
    v_cod_produto := r_na.codigo;
   ELSE
    -- natureza customizada.
    -- seleciona o tipo de produto ND
    v_cod_produto := 'ND';
   END IF;
   --
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_id
     FROM tipo_produto
    WHERE codigo = v_cod_produto
      AND flag_sistema = 'S'
      AND empresa_id = v_empresa_id;
   --
   IF v_tipo_produto_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável não existe para essa empresa (' || v_cod_produto || ').';
    RAISE v_exception;
   END IF;
   --
   IF r_na.flag_inc_a = 'S' OR v_cod_produto = 'ND'
   THEN
    v_ordem_item := v_ordem_item + 1;
    --
    INSERT INTO item
     (item_id,
      job_id,
      orcamento_id,
      tipo_produto_id,
      natureza_item,
      tipo_item,
      complemento,
      quantidade,
      frequencia,
      custo_unitario,
      valor_aprovado,
      flag_parcelado,
      flag_sem_valor,
      status_fatur,
      ordem_grupo,
      ordem_subgrupo,
      ordem_item,
      ordem_grupo_sq,
      ordem_subgrupo_sq,
      ordem_item_sq)
    VALUES
     (seq_item.nextval,
      v_job_id,
      p_orcamento_id,
      v_tipo_produto_id,
      r_na.codigo,
      'A',
      'sobre A',
      1,
      1,
      0,
      0,
      'N',
      'N',
      'NLIB',
      0,
      0,
      v_ordem_item,
      0,
      0,
      v_ordem_item);
   END IF;
   --
   IF r_na.flag_inc_b = 'S' OR v_cod_produto = 'ND'
   THEN
    v_ordem_item := v_ordem_item + 1;
    --
    INSERT INTO item
     (item_id,
      job_id,
      orcamento_id,
      tipo_produto_id,
      natureza_item,
      tipo_item,
      complemento,
      quantidade,
      frequencia,
      custo_unitario,
      valor_aprovado,
      flag_parcelado,
      flag_sem_valor,
      status_fatur,
      ordem_grupo,
      ordem_subgrupo,
      ordem_item,
      ordem_grupo_sq,
      ordem_subgrupo_sq,
      ordem_item_sq)
    VALUES
     (seq_item.nextval,
      v_job_id,
      p_orcamento_id,
      v_tipo_produto_id,
      r_na.codigo,
      'B',
      'sobre B',
      1,
      1,
      0,
      0,
      'N',
      'N',
      'NLIB',
      0,
      0,
      v_ordem_item,
      0,
      0,
      v_ordem_item);
   END IF;
   --
   IF r_na.flag_inc_c = 'S' OR v_cod_produto = 'ND'
   THEN
    v_ordem_item := v_ordem_item + 1;
    --
    INSERT INTO item
     (item_id,
      job_id,
      orcamento_id,
      tipo_produto_id,
      natureza_item,
      tipo_item,
      complemento,
      quantidade,
      frequencia,
      custo_unitario,
      valor_aprovado,
      flag_parcelado,
      flag_sem_valor,
      status_fatur,
      ordem_grupo,
      ordem_subgrupo,
      ordem_item,
      ordem_grupo_sq,
      ordem_subgrupo_sq,
      ordem_item_sq)
    VALUES
     (seq_item.nextval,
      v_job_id,
      p_orcamento_id,
      v_tipo_produto_id,
      r_na.codigo,
      'C',
      'sobre C',
      1,
      1,
      0,
      0,
      'N',
      'N',
      'NLIB',
      0,
      0,
      v_ordem_item,
      0,
      0,
      v_ordem_item);
   END IF;
  END LOOP; -- fim do loop por natureza do item   
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
 END totais_gerar;
 --
 --
 PROCEDURE totais_recalcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Recalcula totais do orcamento (CPMF, HONOR, ENCARGOS).
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            12/05/2014  Uso do flag_com_encargo.
  -- Silvia            14/10/2014  Uso do flag_com_encargo_honor.
  -- Silvia            14/09/2016  Naturezas de item configuraveis.
  -- Silvia            10/11/2022  Nova modalidade de calculo (DIV) de natureza do item
  -- Silvia            10/08/2023  Ajuste no calculo de naturezas customizadas
  -- Silvia            17/08/2023  Mudanca de toda a logica para uso de nova funcao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_empresa_id      job.empresa_id%TYPE;
  v_valor_calculado NUMBER;
  --
  -- seleciona as naturezas de totais a serem recalculadas
  -- (nao CUSTO) instanciadas no orcamento
  CURSOR c_it IS
   SELECT it.item_id,
          it.tipo_item,
          it.natureza_item,
          na.natureza_item_id,
          na.flag_inc_a,
          na.flag_inc_b,
          na.flag_inc_c,
          na.mod_calculo,
          oc.valor_padrao,
          na.tipo AS tipo_natureza
     FROM item            it,
          natureza_item   na,
          orcam_nitem_pdr oc
    WHERE it.orcamento_id = p_orcamento_id
      AND it.natureza_item <> 'CUSTO'
      AND it.natureza_item = na.codigo
      AND na.empresa_id = v_empresa_id
      AND na.natureza_item_id = oc.natureza_item_id
      AND oc.orcamento_id = it.orcamento_id
      FOR UPDATE
    ORDER BY na.ordem,
             it.tipo_item;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.empresa_id
    INTO v_empresa_id
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   -- loop por item de total a ser recalculado
   SELECT nvl(SUM(item_pkg.valor_natureza_retornar(it.item_id, r_it.natureza_item)), 0)
     INTO v_valor_calculado
     FROM item it
    WHERE orcamento_id = p_orcamento_id
      AND natureza_item = 'CUSTO'
      AND tipo_item = r_it.tipo_item;
   -- 
   UPDATE item
      SET valor_aprovado   = v_valor_calculado,
          valor_fornecedor = v_valor_calculado
    WHERE item_id = r_it.item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
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
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END totais_recalcular;
 --
 --
 PROCEDURE enderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/10/2016
  -- DESCRICAO: subrotina que endereca um determinado usuario ao orcamento, caso ele ainda 
  -- nao  esteja enderecado. 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/10/2019  Eliminacao do papel no enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_orcamento_id      IN orcam_usuario.orcamento_id%TYPE,
  p_usuario_id        IN orcam_usuario.usuario_id%TYPE,
  p_atuacao           IN orcam_usuario.atuacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_papel_id       papel.papel_id%TYPE;
  v_papel_ender_id papel.papel_id%TYPE;
  v_exception      EXCEPTION;
  v_cod_priv       privilegio.codigo%TYPE;
  --
 BEGIN
  v_qt := 0;
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
  IF p_atuacao NOT IN ('CRIA', 'APROV', 'TERM', 'ENDER') OR TRIM(p_atuacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Atuação inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_atuacao = 'CRIA'
  THEN
   v_cod_priv := 'ORCAMENTO_I';
  ELSIF p_atuacao = 'APROV'
  THEN
   v_cod_priv := 'ORCAMENTO_AP';
  ELSE
   v_cod_priv := 'ORCAMENTO_A';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se o usuario ja esta enderecado no orcamento
  -- com essa atuacao
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_usuario
   WHERE orcamento_id = p_orcamento_id
     AND usuario_id = p_usuario_id
     AND atuacao = p_atuacao;
  --
  IF v_qt = 0
  THEN
   -- usuario ainda nao esta enderecado com essa atuacao 
   INSERT INTO orcam_usuario
    (orcamento_id,
     usuario_id,
     atuacao,
     data)
   VALUES
    (p_orcamento_id,
     p_usuario_id,
     p_atuacao,
     SYSDATE);
  END IF;
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
 END enderecar_usuario;
 --
 --
 PROCEDURE enderecar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/10/2016
  -- DESCRICAO: Enderecamento de usuarios do orcamento
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/10/2019  Eliminacao do papel no enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_vetor_usuarios VARCHAR2(500);
  v_delimitador    CHAR(1);
  v_usuario_id     usuario.usuario_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.numero),
         MAX(jo.status)
    INTO v_numero_job,
         v_status_job
    FROM job       jo,
         orcamento oc
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  DELETE FROM orcam_usuario
   WHERE orcamento_id = p_orcamento_id
     AND atuacao = 'ENDER';
  --
  v_delimitador    := '|';
  v_vetor_usuarios := rtrim(p_vetor_usuarios);
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM orcam_usuario
    WHERE orcamento_id = p_orcamento_id
      AND usuario_id = v_usuario_id
      AND atuacao = 'ENDER';
   --
   IF v_qt = 0
   THEN
    INSERT INTO orcam_usuario
     (orcamento_id,
      usuario_id,
      atuacao,
      data)
    VALUES
     (p_orcamento_id,
      v_usuario_id,
      'ENDER',
      SYSDATE);
    --
    -- geracao de evento
    v_identif_objeto := orcamento_pkg.numero_formatar(p_orcamento_id);
    v_compl_histor   := 'Endereçamento manual';
    --
    evento_pkg.gerar(p_usuario_sessao_id,
                     p_empresa_id,
                     'ORCAMENTO',
                     'ENDERECAR',
                     v_identif_objeto,
                     p_orcamento_id,
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
    INSERT INTO notifica_usu_avulso
     (historico_id,
      usuario_id,
      papel_id,
      tipo_notifica)
    VALUES
     (v_historico_id,
      v_usuario_id,
      NULL,
      'PADRAO');
   END IF;
  END LOOP;
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
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 16/06/2020
  -- DESCRICAO: Adicionar arquivo no Orcamento (Estimativa de Custos).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/12/2022  Novo privilegio para arquivo de aprov cliente.
  -- Ana Luiza         10/01/2025  Criado novo evento para notificar usuario que adiciona arquivo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_orcamento_id      IN arquivo_orcamento.orcamento_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_tipo_arq_orcam    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_status_orcam    orcamento.status%TYPE;
  v_num_orcamento   orcamento.num_orcamento%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  --
 BEGIN
  --
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa estimativa de custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = p_tipo_arq_orcam;
  --
  IF v_tipo_arquivo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de arquivo não existe (' || p_tipo_arq_orcam || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT oc.job_id,
         oc.status,
         jo.numero,
         jo.status,
         oc.num_orcamento
    INTO v_job_id,
         v_status_orcam,
         v_numero_job,
         v_status_job,
         v_num_orcamento
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  IF p_tipo_arq_orcam = 'ORCAMENTO_APROV'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAM_ARQCLI_C',
                                 p_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_A',
                                 p_orcamento_id,
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
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
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
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_orcamento_id,
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
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_orcamento;
  v_compl_histor   := 'Anexação de arquivo (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
  --ALCBO_100125
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'NOTIFICAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 16/06/2020
  -- DESCRICAO: Excluir arquivo de Orcamento (Estimativa de Custos)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/12/2022  Novo privilegio para arquivo de aprov cliente.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_orcamento_id      IN arquivo_orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_orcam     orcamento.status%TYPE;
  v_num_orcamento    orcamento.num_orcamento%TYPE;
  v_nome_original    arquivo.nome_original%TYPE;
  v_cod_tipo_arquivo tipo_arquivo.codigo%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_xml_ates         CLOB;
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
    FROM arquivo_orcamento
   WHERE arquivo_id = p_arquivo_id
     AND orcamento_id = p_orcamento_id;
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
    FROM arquivo_orcamento ao,
         arquivo           ar,
         tipo_arquivo      ta
   WHERE ao.arquivo_id = p_arquivo_id
     AND ao.orcamento_id = p_orcamento_id
     AND ao.arquivo_id = ar.arquivo_id
     AND ar.tipo_arquivo_id = ta.tipo_arquivo_id;
  --
  SELECT oc.job_id,
         oc.status,
         jo.numero,
         jo.status,
         oc.num_orcamento
    INTO v_job_id,
         v_status_orcam,
         v_numero_job,
         v_status_job,
         v_num_orcamento
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  IF v_cod_tipo_arquivo = 'ORCAMENTO_APROV'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAM_ARQCLI_C',
                                 p_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ORCAMENTO_A',
                                 p_orcamento_id,
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
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_040725
  orcamento_pkg.xml_gerar(p_orcamento_id, v_xml_ates, p_erro_cod, p_erro_msg);
  --
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_num_orcamento;
  v_compl_histor   := 'Exclusão de arquivo (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_ates,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --ALCBO_040725
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'EXCLUIR_ARQ',
                   v_identif_objeto,
                   p_orcamento_id,
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
 PROCEDURE saldos_acessorios_recalcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 01/09/2008
  -- DESCRICAO: Recalcula saldos dos acessorios (CPMF, HONOR, ENCARGOS) do orcamento.
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/09/2016  Naturezas de item configuraveis (ordenacao no cursor)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  CURSOR c_it IS
   SELECT item_id
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND natureza_item <> 'CUSTO'
    ORDER BY ordem_item,
             tipo_item;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
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
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- saldos_acessorios_recalcular
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 26/01/2017
  -- DESCRICAO: Subrotina que gera o xml do orcamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_xml          OUT CLOB,
  p_erro_cod     OUT VARCHAR2,
  p_erro_msg     OUT VARCHAR2
 ) IS
  v_qt          INTEGER;
  v_exception   EXCEPTION;
  v_valor_total NUMBER;
  v_valor_itens NUMBER;
  v_xml         xmltype;
  v_xml_aux1    xmltype;
  v_xml_aux99   xmltype;
  v_xml_doc     VARCHAR2(100);
  --
  CURSOR c_na IS
   SELECT na.codigo,
          na.nome,
          numero_mostrar(oc.valor_padrao, 6, 'N') valor_padrao,
          na.mod_calculo,
          na.ordem
     FROM orcam_nitem_pdr oc,
          natureza_item   na
    WHERE na.natureza_item_id = oc.natureza_item_id
      AND oc.orcamento_id = p_orcamento_id
    ORDER BY na.ordem;
  --
  CURSOR c_it IS
   SELECT it.item_id,
          it.natureza_item,
          it.tipo_item || to_char(it.num_seq) AS num_item,
          tp.nome AS tipo_produto,
          numero_mostrar(it.quantidade, 2, 'N') quantidade,
          numero_mostrar(it.frequencia, 2, 'N') frequencia,
          numero_mostrar(it.custo_unitario, 5, 'N') custo_unitario,
          numero_mostrar(it.valor_aprovado, 2, 'N') valor_aprovado
     FROM item         it,
          tipo_produto tp
    WHERE it.orcamento_id = p_orcamento_id
      AND it.tipo_produto_id = tp.tipo_produto_id
    ORDER BY decode(it.natureza_item, 'CUSTO', 1, 2),
             it.tipo_item,
             it.num_seq,
             it.ordem_item_sq;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_total
    FROM item
   WHERE orcamento_id = p_orcamento_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_itens
    FROM item
   WHERE orcamento_id = p_orcamento_id
     AND natureza_item = 'CUSTO';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("orcamento_id", to_char(oc.orcamento_id)),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("status_job", jo.status),
                   xmlelement("numero_estim", oc.num_orcamento),
                   xmlelement("valor_itens", numero_mostrar(v_valor_itens, 2, 'S')),
                   xmlelement("valor_total", numero_mostrar(v_valor_total, 2, 'S')),
                   xmlelement("data_criacao", data_mostrar(oc.data_criacao)),
                   xmlelement("autor", pa.apelido),
                   xmlelement("descricao", char_especial_retirar(oc.descricao)),
                   xmlelement("tipo_job", tj.nome),
                   xmlelement("servico", se.nome),
                   xmlelement("tipo_financeiro", tf.nome),
                   xmlelement("empresa_fatur", pf.apelido),
                   xmlelement("contato_fatur", pc.apelido),
                   xmlelement("data_prev_ini", data_mostrar(oc.data_prev_ini)),
                   xmlelement("data_prev_fim", data_mostrar(oc.data_prev_fim)),
                   xmlelement("pago_cliente", oc.flag_pago_cliente),
                   xmlelement("despesa", oc.flag_despesa),
                   xmlelement("tem_aprovacao", oc.flag_com_aprov),
                   xmlelement("data_aprov_limite", data_mostrar(oc.data_aprov_limite)),
                   xmlelement("data_aprovacao", data_mostrar(oc.data_aprovacao)),
                   xmlelement("data_prev_fec_check", data_mostrar(oc.data_prev_fec_check)),
                   xmlelement("municipio_servico", oc.municipio_servico),
                   xmlelement("uf_servico", oc.uf_servico),
                   xmlelement("meta_valor_min", numero_mostrar(oc.meta_valor_min, 2, 'N')),
                   xmlelement("meta_valor_max", numero_mostrar(oc.meta_valor_max, 2, 'N')),
                   xmlelement("status_estim", oc.status),
                   xmlelement("data_status", data_mostrar(oc.data_status)),
                   xmlelement("usuario_status", ps.apelido),
                   xmlelement("motivo_status", oc.motivo_status),
                   xmlelement("compl_status", oc.compl_status),
                   xmlelement("ordem_compra", oc.ordem_compra),
                   xmlelement("cod_ext_orcam", oc.cod_ext_orcam))
    INTO v_xml
    FROM orcamento       oc,
         job             jo,
         pessoa          pf,
         pessoa          pa,
         tipo_financeiro tf,
         tipo_job        tj,
         pessoa          ps,
         pessoa          pc,
         servico         se
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id
     AND oc.tipo_job_id = tj.tipo_job_id
     AND oc.emp_faturar_por_id = pf.pessoa_id(+)
     AND oc.usuario_autor_id = pa.usuario_id
     AND oc.tipo_financeiro_id = tf.tipo_financeiro_id(+)
     AND oc.usuario_status_id = ps.usuario_id(+)
     AND oc.contato_fatur_id = pc.pessoa_id(+)
     AND oc.servico_id = se.servico_id(+);
  --
  ------------------------------------------------------------
  -- monta INFO FINAN
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
  -- monta ITENS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_it IN c_it
  LOOP
   SELECT xmlagg(xmlelement("item",
                            xmlelement("item_id", to_char(r_it.item_id)),
                            xmlelement("natureza", r_it.natureza_item),
                            xmlelement("num_item", r_it.num_item),
                            xmlelement("tipo_produto", r_it.tipo_produto),
                            xmlelement("quantidade", r_it.quantidade),
                            xmlelement("frequencia", r_it.frequencia),
                            xmlelement("custo_unitario", r_it.custo_unitario),
                            xmlelement("valor", r_it.valor_aprovado)))
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
  -- junta tudo debaixo de "estimativa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("estimativa", v_xml))
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
 FUNCTION liberado_fatur_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: verifica se um determinado orcamento ja foi aprovado/liberado para faturam.
  --  (status = APROV).    Retorna 1 caso sim e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN INTEGER AS
  v_retorno INTEGER;
  v_qt      INTEGER;
  v_status  orcamento.status%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT status
    INTO v_status
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  IF v_status = 'APROV'
  THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END liberado_fatur_verificar;
 --
 --
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o numero formatado de um determinado orcamento, composto pelo
  --    numero do job concatenado com o numero da estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno           VARCHAR2(100);
  v_qt                INTEGER;
  v_num_orcamento     orcamento.num_orcamento%TYPE;
  v_num_job           job.numero%TYPE;
  v_job_id            job.job_id%TYPE;
  v_num_orcamento_max orcamento.num_orcamento%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         jo.job_id,
         oc.num_orcamento
    INTO v_num_job,
         v_job_id,
         v_num_orcamento
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  SELECT MAX(num_orcamento)
    INTO v_num_orcamento_max
    FROM orcamento
   WHERE job_id = v_job_id;
  --
  IF length(v_num_orcamento_max) <= 2
  THEN
   v_retorno := to_char(v_num_job) || '/' || TRIM(to_char(v_num_orcamento, '00'));
  ELSIF length(v_num_orcamento_max) <= 3
  THEN
   v_retorno := to_char(v_num_job) || '/' || TRIM(to_char(v_num_orcamento, '000'));
  ELSE
   v_retorno := to_char(v_num_job) || '/' || TRIM(to_char(v_num_orcamento, '0000'));
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
 FUNCTION numero_formatar2
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o numero formatado de um determinado orcamento, composto apenas
  --    pelo numero da estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno           VARCHAR2(100);
  v_qt                INTEGER;
  v_num_orcamento     orcamento.num_orcamento%TYPE;
  v_num_job           job.numero%TYPE;
  v_job_id            job.job_id%TYPE;
  v_num_orcamento_max orcamento.num_orcamento%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         jo.job_id,
         oc.num_orcamento
    INTO v_num_job,
         v_job_id,
         v_num_orcamento
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  SELECT MAX(num_orcamento)
    INTO v_num_orcamento_max
    FROM orcamento
   WHERE job_id = v_job_id;
  --
  IF length(v_num_orcamento_max) <= 2
  THEN
   v_retorno := TRIM(to_char(v_num_orcamento, '00'));
  ELSIF length(v_num_orcamento_max) <= 3
  THEN
   v_retorno := TRIM(to_char(v_num_orcamento, '000'));
  ELSE
   v_retorno := TRIM(to_char(v_num_orcamento, '0000'));
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_formatar2;
 --
 --
 FUNCTION qtd_itens_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna a qtd de itens de um determinado orcamento / estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN INTEGER AS
  v_retorno INTEGER;
  v_qt      INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(*)
    INTO v_retorno
    FROM item
   WHERE orcamento_id = p_orcamento_id
     AND natureza_item = 'CUSTO'
     AND flag_sem_valor = 'N';
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END qtd_itens_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor total de um determinado orcamento / estimativa, de acordo
  --   com os tipos de itens especificados nos parametros de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/06/2008  Nova natureza 'PAGO_CLI', 'COM_NF'
  -- Silvia            03/10/2008  Desconto de sobras p/ PAGO_CLI
  -- Silvia            28/11/2008  Nova natureza CUSTO_SALDO.
  -- Silvia            20/01/2009  Ajuste no calculo do PERC_ECONOMIA.
  -- Silvia            08/01/2018  Novas naturezas HONOR_OUT e ENCARGO_OUT.
  ------------------------------------------------------------------------------------------
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno        NUMBER;
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_aux1           NUMBER;
  v_aux2           NUMBER;
  v_tipo_bv        VARCHAR2(10);
  v_valor_sobra    NUMBER;
  v_valor_aprovado NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  /*
    IF p_natureza_item NOT IN ('CUSTO','CPMF','HONOR','ENCARGO','ENCARGO_HONOR',
                               'TOTAL_GERAL','TOTAL_FORNEC','PAGO_CLI',
                               'COM_NF','COM_NF_TOT','BV_FAT','BV_ABA',
                               'PERC_ECONOMIA','CUSTO_SALDO') OR
       TRIM(p_natureza_item) IS NULL THEN
       RAISE v_exception;
    END IF;
  */
  --
  IF TRIM(p_tipo_item) IS NULL
  THEN
   ---------------------------------------------
   -- soma todos os tipos de itens (A+B+C)
   ---------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'TOTAL_FORNEC'
   THEN
    SELECT nvl(SUM(valor_fornecedor), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'PAGO_CLI'
   THEN
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_valor_aprovado
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND flag_sem_valor = 'N'
       AND flag_pago_cliente = 'S';
    --
    SELECT nvl(SUM(valor_sobra_item), 0)
      INTO v_valor_sobra
      FROM item_sobra so,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = so.item_id
       AND it.flag_sem_valor = 'N'
       AND it.flag_pago_cliente = 'S';
    --
    v_retorno := v_valor_aprovado - v_valor_sobra;
    --
   ELSIF p_natureza_item = 'COM_NF'
   THEN
    SELECT nvl(SUM(item_pkg.valor_retornar(item_id, 0, 'COM_NF')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id;
    --
   ELSIF p_natureza_item = 'COM_NF_TOT'
   THEN
    SELECT nvl(SUM(item_pkg.valor_retornar(item_id, 0, 'COM_NF')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id;
    --
    v_retorno := v_retorno + orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'CPMF', NULL) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'HONOR', NULL) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'ENCARGO', NULL) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'ENCARGO_HONOR', NULL);
    --
   ELSIF p_natureza_item IN ('BV_FAT', 'BV_ABA')
   THEN
    v_tipo_bv := substr(p_natureza_item, 4, 3);
    --
    SELECT nvl(SUM(item_pkg.valor_retornar(it.item_id, ic.carta_acordo_id, 'BV_COM_CA')), 0) +
           nvl(SUM(item_pkg.valor_retornar(it.item_id, ic.carta_acordo_id, 'TIP_COM_CA')), 0)
      INTO v_retorno
      FROM item         it,
           item_carta   ic,
           carta_acordo ca
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = ic.item_id
       AND ic.carta_acordo_id = ca.carta_acordo_id
       AND ca.tipo_fatur_bv = v_tipo_bv;
    --
   ELSIF p_natureza_item = 'PERC_ECONOMIA'
   THEN
    v_aux2 := valor_realizado_retornar(p_orcamento_id, 'SALDO', NULL);
    v_aux1 := valor_retornar(p_orcamento_id, 'PAGO_CLI', NULL) +
              valor_outras_receitas_retornar(p_orcamento_id, 'CUSTO', NULL) +
              valor_realizado_retornar(p_orcamento_id, 'CUSTO', NULL);
    --
    IF v_aux1 <> 0
    THEN
     v_retorno := round(v_aux2 / v_aux1 * 100, 2);
    ELSE
     v_retorno := 0;
    END IF;
    --
   ELSIF p_natureza_item = 'CUSTO_SALDO'
   THEN
    v_retorno := orcamento_pkg.valor_retornar(p_orcamento_id, 'CUSTO', NULL) -
                 orcamento_pkg.valor_abat_retornar(p_orcamento_id, 'CUSTO', NULL);
    --
   ELSIF p_natureza_item = 'HONOR_OUT'
   THEN
    -- outros honorarios customizados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item          it,
           job           jo,
           natureza_item na
     WHERE it.orcamento_id = p_orcamento_id
       AND it.job_id = jo.job_id
       AND it.flag_sem_valor = 'N'
       AND it.natureza_item = na.codigo
       AND na.empresa_id = jo.empresa_id
       AND na.flag_sistema = 'N'
       AND na.tipo = 'HONOR';
   ELSIF p_natureza_item = 'ENCARGO_OUT'
   THEN
    -- outros encargos customizados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item          it,
           job           jo,
           natureza_item na
     WHERE it.orcamento_id = p_orcamento_id
       AND it.job_id = jo.job_id
       AND it.flag_sem_valor = 'N'
       AND it.natureza_item = na.codigo
       AND na.empresa_id = jo.empresa_id
       AND na.flag_sistema = 'N'
       AND na.tipo = 'ENCARGO';
   ELSE
    -- nao se trata de uma natureza "virtual". Soma direto no select.
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = p_natureza_item
       AND flag_sem_valor = 'N';
   END IF;
  ELSE
   ---------------------------------------------------------
   -- soma apenas os itens do tipo especificado (A, B ou C)
   ---------------------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'TOTAL_FORNEC'
   THEN
    SELECT nvl(SUM(valor_fornecedor), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'PAGO_CLI'
   THEN
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_valor_aprovado
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N'
       AND flag_pago_cliente = 'S';
    --
    SELECT nvl(SUM(valor_sobra_item), 0)
      INTO v_valor_sobra
      FROM item_sobra so,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND it.item_id = so.item_id
       AND it.flag_sem_valor = 'N'
       AND it.flag_pago_cliente = 'S';
    --
    v_retorno := v_valor_aprovado - v_valor_sobra;
    --
   ELSIF p_natureza_item = 'COM_NF'
   THEN
    SELECT nvl(SUM(item_pkg.valor_retornar(item_id, 0, 'COM_NF')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item;
    --
   ELSIF p_natureza_item = 'COM_NF_TOT'
   THEN
    SELECT nvl(SUM(item_pkg.valor_retornar(item_id, 0, 'COM_NF')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item;
    --
    v_retorno := v_retorno +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'CPMF', p_tipo_item) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'HONOR', p_tipo_item) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'ENCARGO', p_tipo_item) +
                 orcamento_pkg.valor_realizado_retornar(p_orcamento_id,
                                                        'ENCARGO_HONOR',
                                                        p_tipo_item);
    --
   ELSIF p_natureza_item IN ('BV_FAT', 'BV_ABA')
   THEN
    v_tipo_bv := substr(p_natureza_item, 4, 3);
    --
    SELECT nvl(SUM(item_pkg.valor_retornar(it.item_id, ic.carta_acordo_id, 'BV_COM_CA')), 0) +
           nvl(SUM(item_pkg.valor_retornar(it.item_id, ic.carta_acordo_id, 'TIP_COM_CA')), 0)
      INTO v_retorno
      FROM item         it,
           item_carta   ic,
           carta_acordo ca
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ic.item_id
       AND ic.carta_acordo_id = ca.carta_acordo_id
       AND ca.tipo_fatur_bv = v_tipo_bv;
    --
   ELSIF p_natureza_item = 'PERC_ECONOMIA'
   THEN
    v_aux2 := valor_realizado_retornar(p_orcamento_id, 'SALDO', p_tipo_item);
    v_aux1 := valor_retornar(p_orcamento_id, 'PAGO_CLI', p_tipo_item) +
              valor_outras_receitas_retornar(p_orcamento_id, 'CUSTO', p_tipo_item) +
              valor_realizado_retornar(p_orcamento_id, 'CUSTO', p_tipo_item);
    --
    IF v_aux1 <> 0
    THEN
     v_retorno := round(v_aux2 / v_aux1 * 100, 2);
    ELSE
     v_retorno := 0;
    END IF;
    --
   ELSIF p_natureza_item = 'CUSTO_SALDO'
   THEN
    v_retorno := orcamento_pkg.valor_retornar(p_orcamento_id, 'CUSTO', p_tipo_item) -
                 orcamento_pkg.valor_abat_retornar(p_orcamento_id, 'CUSTO', p_tipo_item);
    --                
   ELSIF p_natureza_item = 'HONOR_OUT'
   THEN
    -- outros honorarios customizados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item          it,
           job           jo,
           natureza_item na
     WHERE it.orcamento_id = p_orcamento_id
       AND it.job_id = jo.job_id
       AND it.flag_sem_valor = 'N'
       AND it.tipo_item = p_tipo_item
       AND it.natureza_item = na.codigo
       AND na.empresa_id = jo.empresa_id
       AND na.flag_sistema = 'N'
       AND na.tipo = 'HONOR';
   ELSIF p_natureza_item = 'ENCARGO_OUT'
   THEN
    -- outros encargos customizados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item          it,
           job           jo,
           natureza_item na
     WHERE it.orcamento_id = p_orcamento_id
       AND it.job_id = jo.job_id
       AND it.flag_sem_valor = 'N'
       AND it.tipo_item = p_tipo_item
       AND it.natureza_item = na.codigo
       AND na.empresa_id = jo.empresa_id
       AND na.flag_sistema = 'N'
       AND na.tipo = 'ENCARGO';
   ELSE
    -- nao se trata de uma natureza "virtual". Soma direto no select.
    SELECT nvl(SUM(valor_aprovado), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = p_natureza_item
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N';
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION valor_outras_receitas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/09/2008
  -- DESCRICAO: retorna o valor de outras receitas de um determinado orcamento/estimativa,
  --   que nao geram faturamento no sistema.
  --   ATENCAO: encargos e honorarios nao entram pois nao tem check-in.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/01/2009  Ajuste para considerar receitas da 100% Incentivo.
  -- Silvia            13/11/2009  Implementacao de receita de contrato.
  ------------------------------------------------------------------------------------------
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno        NUMBER;
  v_valor_parcial1 NUMBER;
  v_valor_parcial2 NUMBER;
  v_valor_parcial3 NUMBER;
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  --
 BEGIN
  v_retorno        := 0;
  v_valor_parcial1 := 0;
  v_valor_parcial2 := 0;
  v_valor_parcial3 := 0;
  --
  /*
    IF p_natureza_item NOT IN ('CUSTO','CPMF','HONOR','ENCARGO','ENCARGO_HONOR',
                               'TOTAL_GERAL') OR
       TRIM(p_natureza_item) IS NULL THEN
       RAISE v_exception;
    END IF;
  */
  --
  IF p_natureza_item IN ('CUSTO', 'TOTAL_GERAL')
  THEN
   -- o calculo so faz sentido p/ CUSTO (acessorios nao tem check-in)
   --
   IF TRIM(p_tipo_item) IS NULL
   THEN
    --
    -- receitas pagas diretamente pela fonte
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial1
      FROM nota_fiscal nf,
           item_nota   io,
           item        it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita IS NOT NULL
       AND nf.resp_pgto_receita = 'FON';
    --
    -- receitas de contratos
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial2
      FROM nota_fiscal nf,
           item_nota   io,
           item        it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita = 'CONTRATO'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
    --
    -- receitas pagas pela Incentivo
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial3
      FROM nota_fiscal nf,
           item_nota   io,
           item        it,
           pessoa      pe
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON'
       AND nf.emp_faturar_por_id = pe.pessoa_id
       AND pe.flag_emp_incentivo = 'S';
   ELSE
    -- receitas pagas diretamente pela fonte
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial1
      FROM nota_fiscal nf,
           item_nota   io,
           item        it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita IS NOT NULL
       AND nf.resp_pgto_receita = 'FON';
    --
    -- receitas de contratos
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial2
      FROM nota_fiscal nf,
           item_nota   io,
           item        it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita = 'CONTRATO'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
    --
    -- receitas pagas pela Incentivo
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_valor_parcial3
      FROM nota_fiscal nf,
           item_nota   io,
           item        it,
           pessoa      pe
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON'
       AND nf.emp_faturar_por_id = pe.pessoa_id
       AND pe.flag_emp_incentivo = 'S';
   END IF;
  END IF;
  --
  v_retorno := v_valor_parcial1 + v_valor_parcial2 + v_valor_parcial3;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_outras_receitas_retornar;
 --
 --
 FUNCTION valor_abat_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/06/2008
  -- DESCRICAO: retorna o valor abatido total de um determinado orcamento / estimativa,
  --   de acordo com os tipos de itens especificados nos parametros de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno     NUMBER;
  v_qt          INTEGER;
  v_exception   EXCEPTION;
  v_valor_sobra NUMBER;
  --
 BEGIN
  v_retorno     := 0;
  v_valor_sobra := 0;
  --
  /*
    IF p_natureza_item NOT IN ('CUSTO','CPMF','HONOR','ENCARGO','ENCARGO_HONOR',
                               'TOTAL_GERAL') OR
       TRIM(p_natureza_item) IS NULL THEN
       RAISE v_exception;
    END IF;
  */
  --
  IF p_natureza_item IN ('CUSTO', 'TOTAL_GERAL') AND
     (TRIM(p_tipo_item) IS NULL OR p_tipo_item = 'A')
  THEN
   -- precisa descobrir as sobras de itens de A pagos pelo cliente,
   -- para somar no abatimento (considerar credito).
   SELECT nvl(SUM(valor_sobra_item), 0)
     INTO v_valor_sobra
     FROM item_sobra so,
          item       it
    WHERE it.orcamento_id = p_orcamento_id
      AND it.flag_sem_valor = 'N'
      AND it.tipo_item = 'A'
      AND it.flag_pago_cliente = 'S'
      AND it.item_id = so.item_id;
  END IF;
  --
  IF TRIM(p_tipo_item) IS NULL
  THEN
   --------------------------------------------
   -- soma todos os tipos de itens
   --------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_retorno
      FROM item_abat ia,
           item      it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = ia.item_id;
   ELSE
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_retorno
      FROM item_abat ia,
           item      it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.natureza_item = p_natureza_item
       AND it.item_id = ia.item_id;
   END IF;
  ELSE
   --------------------------------------------
   -- soma apenas os itens do tipo especificado
   --------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_retorno
      FROM item_abat ia,
           item      it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ia.item_id;
   ELSE
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_retorno
      FROM item_abat ia,
           item      it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.natureza_item = p_natureza_item
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ia.item_id;
   END IF;
  END IF;
  --
  v_retorno := v_retorno + v_valor_sobra;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_abat_retornar;
 --
 --
 FUNCTION valor_cred_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/06/2008
  -- DESCRICAO: retorna o valor de credito de um determinado orcamento / estimativa,
  --   de acordo com os tipos de itens especificados nos parametros de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  /*
    IF p_natureza_item NOT IN ('CUSTO','CPMF','HONOR','ENCARGO','ENCARGO_HONOR',
                               'TOTAL_GERAL') OR
       TRIM(p_natureza_item) IS NULL THEN
       RAISE v_exception;
    END IF;
  */
  --
  IF TRIM(p_tipo_item) IS NULL
  THEN
   -- soma todos os tipos de itens
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(ia.valor_cred_item), 0)
      INTO v_retorno
      FROM item_sobra ia,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = ia.item_id;
   ELSE
    SELECT nvl(SUM(ia.valor_cred_item), 0)
      INTO v_retorno
      FROM item_sobra ia,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.natureza_item = p_natureza_item
       AND it.item_id = ia.item_id;
   END IF;
  ELSE
   -- soma apenas os itens do tipo especificado
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(ia.valor_cred_item), 0)
      INTO v_retorno
      FROM item_sobra ia,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ia.item_id;
   ELSE
    SELECT nvl(SUM(ia.valor_cred_item), 0)
      INTO v_retorno
      FROM item_sobra ia,
           item       it
     WHERE it.orcamento_id = p_orcamento_id
       AND it.natureza_item = p_natureza_item
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ia.item_id;
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_cred_retornar;
 --
 --
 FUNCTION valor_fornec_apagar_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor pendente de pagto a fornecedores de um determinado
  --      orcamento / estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(SUM(io.valor_aprovado), 0)
    INTO v_retorno
    FROM item        it,
         item_nota   io,
         nota_fiscal no
   WHERE it.orcamento_id = p_orcamento_id
     AND it.flag_sem_valor = 'N'
     AND it.item_id = io.item_id
     AND io.nota_fiscal_id = no.nota_fiscal_id
     AND no.status = 'CHECKIN_OK';
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_fornec_apagar_retornar;
 --
 --
 FUNCTION valor_checkin_pend_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2007
  -- DESCRICAO: retorna o valor pendente de check-in de um determinado orcamento/estimativa.
  --   Para itens de A, a pendencia é calculada considerando o valor total do item, mesmo
  --   nao existindo carta acordo.
  --   Para itens de B/C considera apenas a parte que tem carta acordo sem check-in.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/01/2008  Novo parametro (p_tipo_item: A, B, C ou T - todos).
  -- Silvia            31/03/2008  Calculo de sobras (via funcao de item).
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_item    IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_item = 'T'
  THEN
   --SELECT NVL(SUM(item_pkg.valor_checkin_pend_retornar(item_id)),0)
   SELECT nvl(SUM(valor_ckpend), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND flag_sem_valor = 'N'
      AND natureza_item = 'CUSTO';
  ELSE
   --SELECT NVL(SUM(item_pkg.valor_checkin_pend_retornar(item_id)),0)
   SELECT nvl(SUM(valor_ckpend), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND flag_sem_valor = 'N'
      AND natureza_item = 'CUSTO';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_checkin_pend_retornar;
 --
 --
 FUNCTION valor_geral_pend_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 04/04/2008
  -- DESCRICAO: retorna o geral pendente de um determinado orcamento/estimativa.
  --   Quando o orcamento tiver valor pendente maior que zero, indica que o orcamento ainda
  --   nao teve o check-in encerrado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_item    IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_item = 'T' OR p_tipo_item IS NULL
  THEN
   --SELECT NVL(SUM(item_pkg.valor_retornar(item_id,0,'SEM_NF')),0)
   SELECT nvl(SUM(valor_cksaldo), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND flag_sem_valor = 'N'
      AND natureza_item = 'CUSTO';
  ELSE
   --SELECT NVL(SUM(item_pkg.valor_retornar(item_id,0,'SEM_NF')),0)
   SELECT nvl(SUM(valor_cksaldo), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND tipo_item = p_tipo_item
      AND flag_sem_valor = 'N'
      AND natureza_item = 'CUSTO';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_geral_pend_retornar;
 --
 --
 FUNCTION valor_realizado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor realizado de um determinado orcamento , de acordo
  --  com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/07/2008  Nova natureza 'PAGO_CLI'
  -- Silvia            20/01/2009  Ajuste no calculo do SALDO.
  ------------------------------------------------------------------------------------------
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  v_aux1      NUMBER;
  v_aux2      NUMBER;
  v_tipo_bv   VARCHAR2(10);
  --
 BEGIN
  v_retorno := 0;
  --
  /*
    IF p_natureza_item NOT IN ('CUSTO','CPMF','HONOR','ENCARGO','ENCARGO_HONOR',
                               'TOTAL_GERAL','SALDO','BV_FAT','BV_ABA','PAGO_CLI') OR
       TRIM(p_natureza_item) IS NULL THEN
       RAISE v_exception;
    END IF;
  */
  --
  IF TRIM(p_tipo_item) IS NULL
  THEN
   -------------------------------------------------
   -- soma todos os tipos de itens
   -------------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(item_pkg.valor_realizado_retornar(item_id, 'FATURADO')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'SALDO'
   THEN
    --
    v_retorno := orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'CUSTO', NULL) +
                 orcamento_pkg.valor_retornar(p_orcamento_id, 'PAGO_CLI', NULL) +
                 orcamento_pkg.valor_outras_receitas_retornar(p_orcamento_id, 'CUSTO', NULL) -
                 orcamento_pkg.valor_retornar(p_orcamento_id, 'COM_NF', NULL);
    --
   ELSIF p_natureza_item IN ('BV_FAT', 'BV_ABA')
   THEN
    v_tipo_bv := substr(p_natureza_item, 4, 3);
    --
    /*
    SELECT NVL(SUM(io.valor_bv + io.valor_tip),0)
      INTO v_aux1
      FROM item it,
           item_carta ic,
           carta_acordo ca,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = ic.item_id
       AND ic.carta_acordo_id = ca.carta_acordo_id
       AND ca.tipo_fatur_bv = v_tipo_bv
       AND it.item_id = io.item_id
       AND ca.carta_acordo_id = io.carta_acordo_id;*/
    --
    SELECT nvl(SUM(io.valor_bv + io.valor_tip), 0)
      INTO v_aux1
      FROM item        it,
           item_nota   io,
           nota_fiscal nf
     WHERE it.orcamento_id = p_orcamento_id
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND io.carta_acordo_id IS NOT NULL
       AND nf.tipo_fatur_bv = v_tipo_bv;
    --
    SELECT nvl(SUM(io.valor_bv + io.valor_tip), 0)
      INTO v_aux2
      FROM item      it,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_fatur_bv = v_tipo_bv
       AND it.item_id = io.item_id
       AND io.carta_acordo_id IS NULL;
    --
    v_retorno := v_aux1 + v_aux2;
    --
   ELSIF p_natureza_item = 'PAGO_CLI'
   THEN
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.flag_sem_valor = 'N'
       AND it.flag_pago_cliente = 'S'
       AND it.item_id = io.item_id;
   ELSE
    SELECT nvl(SUM(item_pkg.valor_realizado_retornar(item_id, 'FATURADO')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = p_natureza_item
       AND flag_sem_valor = 'N';
   END IF;
  ELSE
   -------------------------------------------------
   -- soma apenas os itens do tipo especificado
   -------------------------------------------------
   IF p_natureza_item = 'TOTAL_GERAL'
   THEN
    SELECT nvl(SUM(item_pkg.valor_realizado_retornar(item_id, 'FATURADO')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N';
    --
   ELSIF p_natureza_item = 'SALDO'
   THEN
    --
    v_retorno := orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'CUSTO', p_tipo_item) +
                 orcamento_pkg.valor_retornar(p_orcamento_id, 'PAGO_CLI', p_tipo_item) +
                 orcamento_pkg.valor_outras_receitas_retornar(p_orcamento_id, 'CUSTO', p_tipo_item) -
                 orcamento_pkg.valor_retornar(p_orcamento_id, 'COM_NF', p_tipo_item);
    --
   ELSIF p_natureza_item IN ('BV_FAT', 'BV_ABA')
   THEN
    v_tipo_bv := substr(p_natureza_item, 4, 3);
    --
    /*
    SELECT NVL(SUM(io.valor_bv + io.valor_tip),0)
      INTO v_aux1
      FROM item it,
           item_carta ic,
           carta_acordo ca,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = ic.item_id
       AND ic.carta_acordo_id = ca.carta_acordo_id
       AND ca.tipo_fatur_bv = v_tipo_bv
       AND it.item_id = io.item_id
       AND ca.carta_acordo_id = io.carta_acordo_id;*/
    --
    SELECT nvl(SUM(io.valor_bv + io.valor_tip), 0)
      INTO v_aux1
      FROM item        it,
           item_nota   io,
           nota_fiscal nf
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.item_id = io.item_id
       AND io.nota_fiscal_id = nf.nota_fiscal_id
       AND io.carta_acordo_id IS NOT NULL
       AND nf.tipo_fatur_bv = v_tipo_bv;
    --
    SELECT nvl(SUM(io.valor_bv + io.valor_tip), 0)
      INTO v_aux2
      FROM item      it,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.tipo_fatur_bv = v_tipo_bv
       AND it.item_id = io.item_id
       AND io.carta_acordo_id IS NULL;
    --
    v_retorno := v_aux1 + v_aux2;
    --
   ELSIF p_natureza_item = 'PAGO_CLI'
   THEN
    SELECT nvl(SUM(io.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           item_nota io
     WHERE it.orcamento_id = p_orcamento_id
       AND it.tipo_item = p_tipo_item
       AND it.flag_sem_valor = 'N'
       AND it.flag_pago_cliente = 'S'
       AND it.item_id = io.item_id;
   ELSE
    SELECT nvl(SUM(item_pkg.valor_realizado_retornar(item_id, 'FATURADO')), 0)
      INTO v_retorno
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = p_natureza_item
       AND tipo_item = p_tipo_item
       AND flag_sem_valor = 'N';
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_realizado_retornar;
 --
 --
 FUNCTION valor_rentab_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/06/2008
  -- DESCRICAO: retorna o valor ou percentual de rentabilidade de um determinado
  --    orcamento, de acordo com o tipo especificado (usado no relatorio de rentabilidade).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_calculo IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  v_aux       NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_calculo NOT IN ('PERC_SALDO', 'TOT_RENT', 'PERC_RENT_COMHOR', 'PERC_RENT_SEMHOR')
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_calculo = 'PERC_SALDO'
  THEN
   v_aux := orcamento_pkg.valor_retornar(p_orcamento_id, 'TOTAL_GERAL', NULL);
   --
   IF v_aux <> 0
   THEN
    v_retorno := round(orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'SALDO', NULL) /
                       v_aux * 100,
                       2);
   END IF;
  ELSIF p_tipo_calculo = 'TOT_RENT'
  THEN
   v_retorno := orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'HONOR', NULL) +
                orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'SALDO', NULL) +
                orcamento_pkg.valor_retornar(p_orcamento_id, 'BV_FAT', NULL) +
                orcamento_pkg.valor_retornar(p_orcamento_id, 'BV_ABA', NULL) -
                orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'ENCARGO_HONOR', NULL);
  ELSIF p_tipo_calculo = 'PERC_RENT_COMHOR'
  THEN
   v_aux := orcamento_pkg.valor_retornar(p_orcamento_id, 'TOTAL_GERAL', NULL);
   --
   IF v_aux <> 0
   THEN
    v_retorno := round(orcamento_pkg.valor_rentab_retornar(p_orcamento_id, 'TOT_RENT') / v_aux * 100,
                       2);
   END IF;
  ELSIF p_tipo_calculo = 'PERC_RENT_SEMHOR'
  THEN
   v_aux := orcamento_pkg.valor_retornar(p_orcamento_id, 'TOTAL_GERAL', NULL);
   --
   IF v_aux <> 0
   THEN
    v_retorno := round((orcamento_pkg.valor_realizado_retornar(p_orcamento_id, 'SALDO', NULL) +
                       orcamento_pkg.valor_retornar(p_orcamento_id, 'BV_FAT', NULL) +
                       orcamento_pkg.valor_retornar(p_orcamento_id, 'BV_ABA', NULL)) / v_aux * 100,
                       2);
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_rentab_retornar;
 --
 --
 FUNCTION parcelado_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/01/2008
  -- DESCRICAO: verifica se todos os itens do orcamento estao parcelados.
  --    Serve apenas p/ itens de natureza CUSTO (para os demais, retorna sempre 1).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(MIN(item_pkg.parcelado_verificar(item_id)), 0)
    INTO v_retorno
    FROM item
   WHERE orcamento_id = p_orcamento_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END parcelado_verificar;
 --
 --
 FUNCTION carta_acordo_ok_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/01/2008
  -- DESCRICAO: verifica se todos os itens do orcamento estao com as cartas acordo ja
  --  definidas e emitidas.  Serve apenas p/ itens de A (para B e C retorna sempre 1).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(MIN(item_pkg.carta_acordo_ok_verificar(item_id)), 0)
    INTO v_retorno
    FROM item
   WHERE orcamento_id = p_orcamento_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END carta_acordo_ok_verificar;
 --
--
END; -- ORCAMENTO_PKG

/
