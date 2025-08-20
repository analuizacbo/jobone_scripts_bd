--------------------------------------------------------
--  DDL for Package Body EMPRESA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "EMPRESA_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 24/05/2010
  -- DESCRICAO: Inclusão de EMPRESA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/09/2016  Carga de natureza_item
  -- Silvia            22/06/2017  Novos atributos pais e localidade
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            28/02/2019  Carga de status_aux_oport
  -- Silvia            04/02/2021  Copia de novos atributos de condicao_pagto
  -- Ana Luiza         25/11/2024  Remocao categoria da tab tipo_produto
  -- Ana Luiza         03/07/2025  Adicao de ordem para nao dar problema de insert null 
  --                               em condicao de pagto e insert de classe e categoria 
  --                               padrão para empresa nova criada
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_nome              IN empresa.nome%TYPE,
  p_codigo            IN empresa.codigo%TYPE,
  p_cod_ext_empresa   IN empresa.cod_ext_empresa%TYPE,
  p_pais_id           IN pais.pais_id%TYPE,
  p_localidade        IN VARCHAR2,
  p_empresa_id        OUT empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_empresa_id        empresa.empresa_id%TYPE;
  v_empresa_old_id    empresa.empresa_id%TYPE;
  v_condicao_pagto_id condicao_pagto.condicao_pagto_id%TYPE;
  v_area_id           area.area_id%TYPE;
  v_papel_id          papel.papel_id%TYPE;
  v_classe_produto_id classe_produto.classe_produto_id%TYPE;
  v_tipo_produto_id   tipo_produto.tipo_produto_id%TYPE;
  v_grupo_id          grupo.grupo_id%TYPE;
  v_pessoa_id         pessoa.pessoa_id%TYPE;
  v_tipo_os_id        tipo_os.tipo_os_id%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_atual         CLOB;
  v_tab_feriado_id    tab_feriado.tab_feriado_id%TYPE;
  v_categoria_id      categoria.categoria_id%TYPE;
  --
  CURSOR c_cp IS
   SELECT condicao_pagto_id AS condicao_pagto_old_id,
          codigo,
          nome,
          descricao,
          flag_ativo,
          tipo_regra,
          semana_mes,
          dia_util_mes,
          flag_pag_for,
          flag_fat_cli,
          ordem --ALCBO_030725
     FROM condicao_pagto
    WHERE empresa_id = v_empresa_old_id;
  --
  CURSOR c_tos IS
   SELECT tipo_os_id AS tipo_os_old_id
     FROM tipo_os
    WHERE empresa_id = v_empresa_old_id
      AND flag_ativo = 'S';
  --
  CURSOR c_pa IS
   SELECT ar.nome     AS nome_area,
          pa.papel_id AS papel_old_id
     FROM papel pa,
          area  ar
    WHERE pa.empresa_id = v_empresa_old_id
      AND pa.area_id = ar.area_id;
  --
  CURSOR c_tp IS
   SELECT cl.cod_classe,
          cl.sub_classe,
          cl.nome_classe,
          pr.tipo_produto_id AS tipo_produto_old_id,
          pr.nome,
          pr.codigo,
          pr.flag_ativo,
          pr.flag_sistema,
          pr.variacoes,
          pr.tempo_exec_info,
          pr.categoria_id
     FROM tipo_produto   pr,
          classe_produto cl,
          categoria      ca
    WHERE pr.empresa_id = v_empresa_old_id
      AND pr.flag_ativo = 'S'
      AND pr.flag_sistema = 'N'
      AND ca.classe_produto_id = cl.classe_produto_id(+);
  --
  CURSOR c_pe IS
   SELECT pessoa_id AS pessoa_old_id
     FROM pessoa pe
    WHERE pe.empresa_id = v_empresa_old_id
      AND pe.flag_ativo = 'S'
      AND pe.usuario_id IS NULL;
  --
  CURSOR c_re IS
   SELECT pa.pessoa_id AS pessoa_pai_id,
          fi.pessoa_id AS pessoa_filho_id
     FROM relacao re,
          pessoa  pa,
          pessoa  fi
    WHERE re.pessoa_pai_id = to_number(pa.cod_ext_pessoa)
      AND pa.empresa_id = v_empresa_id
      AND re.pessoa_filho_id = to_number(fi.cod_ext_pessoa)
      AND fi.empresa_id = v_empresa_id;
  --
  CURSOR c_fe IS
   SELECT tab_feriado_id,
          nome
     FROM tab_feriado
    WHERE empresa_id = v_empresa_old_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de segurana
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id
     AND flag_admin = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  -- tenta achar uma empresa previamente cadastrada para servir de
  -- base para carga de algumas tabelas (feriado, condicao pagto, etc).
  SELECT MAX(empresa_id)
    INTO v_empresa_old_id
    FROM empresa
   WHERE flag_ativo = 'S';
  --
  IF v_empresa_old_id IS NULL
  THEN
   SELECT MIN(empresa_id)
     INTO v_empresa_old_id
     FROM empresa;
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
  IF rtrim(p_codigo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(codigo) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(cod_ext_empresa) = TRIM(upper(p_cod_ext_empresa));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código externo de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_pais_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do país é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pais
   WHERE pais_id = p_pais_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse país não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_localidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da localidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('localidade', p_localidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Localidade inválida (' || p_localidade || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_empresa.nextval
    INTO v_empresa_id
    FROM dual;
  --
  INSERT INTO empresa
   (empresa_id,
    nome,
    codigo,
    cod_ext_empresa,
    flag_ativo,
    pais_id,
    localidade)
  VALUES
   (v_empresa_id,
    TRIM(p_nome),
    TRIM(p_codigo),
    TRIM(p_cod_ext_empresa),
    'S',
    zvl(p_pais_id, NULL),
    TRIM(p_localidade));
  --
  ------------------------------------------------------------
  -- carga de parametros
  ------------------------------------------------------------
  IF v_empresa_old_id IS NOT NULL
  THEN
   -- carrega parametros da outra empresa
   INSERT INTO empresa_parametro
    (empresa_id,
     parametro_id,
     valor)
    SELECT v_empresa_id,
           parametro_id,
           valor
      FROM empresa_parametro
     WHERE empresa_id = v_empresa_old_id;
  ELSE
   -- carrega parametros com valor padrao
   INSERT INTO empresa_parametro
    (empresa_id,
     parametro_id,
     valor)
    SELECT v_empresa_id,
           parametro_id,
           valor
      FROM parametro;
  END IF;
  --
  ------------------------------------------------------------
  -- carga de status auxiliar do job (padrao)
  ------------------------------------------------------------
  INSERT INTO status_aux_job
   (status_aux_job_id,
    empresa_id,
    cod_status_pai,
    nome,
    ordem,
    flag_padrao,
    flag_ativo)
   SELECT seq_status_aux_job.nextval,
          v_empresa_id,
          codigo,
          descricao,
          1,
          'S',
          'S'
     FROM dicionario
    WHERE tipo = 'status_job';
  --
  ------------------------------------------------------------
  -- carga de status auxiliar da oportunidade (padrao)
  ------------------------------------------------------------
  INSERT INTO status_aux_oport
   (status_aux_oport_id,
    empresa_id,
    cod_status_pai,
    nome,
    ordem,
    flag_padrao,
    flag_ativo)
   SELECT seq_status_aux_job.nextval,
          v_empresa_id,
          codigo,
          descricao,
          1,
          'S',
          'S'
     FROM dicionario
    WHERE tipo = 'status_oportunidade';
  --
  ------------------------------------------------------------
  -- carga de naturezas do item
  ------------------------------------------------------------
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_sistema,
    flag_ativo,
    flag_vinc_ck_a,
    tipo)
  VALUES
   (seq_natureza_item.nextval,
    v_empresa_id,
    'CUSTO',
    'Custo',
    10,
    'NA',
    NULL,
    'N',
    'N',
    'N',
    'S',
    'S',
    'S',
    'CUSTO');
  --
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_sistema,
    flag_ativo,
    flag_vinc_ck_a,
    tipo)
  VALUES
   (seq_natureza_item.nextval,
    v_empresa_id,
    'CPMF',
    'CPMF',
    20,
    'PERC',
    NULL,
    'S',
    'N',
    'N',
    'S',
    'N',
    'N',
    'ENCARGO');
  --
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_sistema,
    flag_ativo,
    flag_vinc_ck_a,
    tipo)
  VALUES
   (seq_natureza_item.nextval,
    v_empresa_id,
    'HONOR',
    'Honorários',
    30,
    'PERC',
    NULL,
    'S',
    'S',
    'N',
    'S',
    'S',
    'S',
    'HONOR');
  --
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_sistema,
    flag_ativo,
    flag_vinc_ck_a,
    tipo)
  VALUES
   (seq_natureza_item.nextval,
    v_empresa_id,
    'ENCARGO',
    'Encargo s/ Custo',
    40,
    'PERC',
    NULL,
    'N',
    'S',
    'S',
    'S',
    'S',
    'N',
    'ENCARGO');
  --
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_sistema,
    flag_ativo,
    flag_vinc_ck_a,
    tipo)
  VALUES
   (seq_natureza_item.nextval,
    v_empresa_id,
    'ENCARGO_HONOR',
    'Encargo s/ Honorários',
    50,
    'PERC',
    NULL,
    'S',
    'S',
    'N',
    'S',
    'S',
    'S',
    'ENCARGO');
  --
  ------------------------------------------------------------
  -- carrega demais tabelas com base em outra empresa
  ------------------------------------------------------------
  IF v_empresa_old_id IS NOT NULL
  THEN
   UPDATE empresa
      SET servidor_arquivo_id =
          (SELECT servidor_arquivo_id
             FROM empresa
            WHERE empresa_id = v_empresa_old_id);
   --
   INSERT INTO padrao_planilha
    (padrao_planilha_id,
     nome,
     arquivo,
     tipo,
     empresa_id)
    SELECT seq_padrao_planilha.nextval,
           nome,
           arquivo,
           tipo,
           v_empresa_id
      FROM padrao_planilha
     WHERE empresa_id = v_empresa_old_id;
   --
   INSERT INTO tipo_arquivo
    (tipo_arquivo_id,
     codigo,
     nome,
     tam_max_arq,
     qtd_max_arq,
     extensoes,
     empresa_id)
    SELECT seq_tipo_arquivo.nextval,
           codigo,
           nome,
           tam_max_arq,
           qtd_max_arq,
           extensoes,
           v_empresa_id
      FROM tipo_arquivo
     WHERE empresa_id = v_empresa_old_id;
   --
   INSERT INTO tipo_documento
    (tipo_documento_id,
     empresa_id,
     codigo,
     nome,
     flag_ativo,
     flag_sistema,
     flag_arq_externo,
     flag_tem_aprov,
     flag_tem_comen,
     flag_tem_cienc,
     tam_max_arq,
     qtd_max_arq,
     extensoes,
     flag_visivel_cli,
     ordem_cli)
    SELECT seq_tipo_documento.nextval,
           v_empresa_id,
           codigo,
           nome,
           flag_ativo,
           flag_sistema,
           flag_arq_externo,
           flag_tem_aprov,
           flag_tem_comen,
           flag_tem_cienc,
           tam_max_arq,
           qtd_max_arq,
           extensoes,
           flag_visivel_cli,
           ordem_cli
      FROM tipo_documento
     WHERE empresa_id = v_empresa_old_id
       AND flag_ativo = 'S'
       AND flag_sistema = 'S';
   --
   ------------------------------------------------------------
   -- carga de feriado
   ------------------------------------------------------------
   /*
   FOR r_fe IN c_fe LOOP
     SELECT seq_tab_feriado.NEXTVAL
       INTO v_tab_feriado_id
       FROM dual;
     --
     -- acrescentar flag_padrao (nova coluna versao 140)
     INSERT INTO tab_feriado (tab_feriado_id, nome, empresa_id)
       VALUES (v_tab_feriado_id, r_fe.nome, v_empresa_id);
     --
     INSERT INTO feriado
                (feriado_id, data, nome, tipo, tab_feriado_id)
          SELECT seq_feriado.NEXTVAL, data, nome, tipo, v_tab_feriado_id
            FROM feriado
           WHERE tab_feriado_id = r_fe.tab_feriado_id
             AND TO_CHAR(data,'YYYY') = TO_CHAR(SYSDATE,'YYYY');
   END LOOP;
   */
   --
   ------------------------------------------------------------
   -- carga de condicao de pagamento
   ------------------------------------------------------------
   FOR r_cp IN c_cp
   LOOP
    SELECT seq_condicao_pagto.nextval
      INTO v_condicao_pagto_id
      FROM dual;
    --
    INSERT INTO condicao_pagto
     (condicao_pagto_id,
      codigo,
      nome,
      empresa_id,
      descricao,
      flag_ativo,
      tipo_regra,
      semana_mes,
      dia_util_mes,
      flag_pag_for,
      flag_fat_cli,
      ordem)
    VALUES
     (v_condicao_pagto_id,
      r_cp.codigo,
      r_cp.nome,
      v_empresa_id,
      r_cp.descricao,
      r_cp.flag_ativo,
      r_cp.tipo_regra,
      r_cp.semana_mes,
      r_cp.dia_util_mes,
      r_cp.flag_pag_for,
      r_cp.flag_fat_cli,
      r_cp.ordem);
    --
    INSERT INTO condicao_pagto_det
     (condicao_pagto_id,
      num_parcela,
      valor_perc,
      num_dias)
     SELECT v_condicao_pagto_id,
            num_parcela,
            valor_perc,
            num_dias
       FROM condicao_pagto_det
      WHERE condicao_pagto_id = r_cp.condicao_pagto_old_id;
    --
    INSERT INTO condicao_pagto_dia
     (condicao_pagto_id,
      dia_semana_id)
     SELECT v_condicao_pagto_id,
            dia_semana_id
       FROM condicao_pagto_dia
      WHERE condicao_pagto_id = r_cp.condicao_pagto_old_id;
   END LOOP;
   --
   ------------------------------------------------------------
   -- carga de tipo de job
   ------------------------------------------------------------
   /*
   INSERT INTO tipo_job
              (tipo_job_id, codigo, nome, empresa_id,
               flag_data_evento, cod_ext_tipo_job, flag_padrao, modelo_briefing)
        SELECT seq_tipo_job.NEXTVAL, codigo, nome, v_empresa_id,
               flag_data_evento, cod_ext_tipo_job, flag_padrao, modelo_briefing
          FROM tipo_job
         WHERE empresa_id = v_empresa_old_id;
   */
   --
   ------------------------------------------------------------
   -- carga de tipo de OS
   ------------------------------------------------------------
   /*
   FOR r_tos IN c_tos LOOP
     SELECT seq_tipo_os.NEXTVAL
       INTO v_tipo_os_id
       FROM dual;
     --
     INSERT INTO tipo_os
                (tipo_os_id, empresa_id, codigo, nome,
                 modelo, modelo_itens, ordem, flag_ativo,
                 flag_tem_corpo, flag_tem_itens, flag_tem_tipo_finan,
                 flag_impr_briefing, flag_item_existente,
                 pontos_tam_p, pontos_tam_m, pontos_tam_g,
                 media_pontos_prev, media_pontos_exec,
                 flag_tem_agenda, flag_tem_descricao, flag_tem_desc_item,
                 flag_tem_importacao, cod_ext_tipo_os, status_integracao,
                 tam_max_arq_ref, qtd_max_arq_ref, extensoes_ref,
                 tam_max_arq_exe, qtd_max_arq_exe, extensoes_exe,
                 tam_max_arq_apr, qtd_max_arq_apr, extensoes_apr,
                 flag_impr_prazo_estim, flag_solic_alt_arqref,
                 flag_exec_alt_arqexe, tipo_termino_exec,
                 flag_pode_pular_aval, flag_aprov_refaz, flag_aprov_devolve)
          SELECT v_tipo_os_id, v_empresa_id, codigo, nome,
                 modelo, modelo_itens, ordem, flag_ativo,
                 flag_tem_corpo, flag_tem_itens, flag_tem_tipo_finan,
                 flag_impr_briefing, flag_item_existente,
                 pontos_tam_p, pontos_tam_m, pontos_tam_g,
                 media_pontos_prev, media_pontos_exec,
                 flag_tem_agenda, flag_tem_descricao, flag_tem_desc_item,
                 flag_tem_importacao, cod_ext_tipo_os, status_integracao,
                 tam_max_arq_ref, qtd_max_arq_ref, extensoes_ref,
                 tam_max_arq_exe, qtd_max_arq_exe, extensoes_exe,
                 tam_max_arq_apr, qtd_max_arq_apr, extensoes_apr,
                 flag_impr_prazo_estim, flag_solic_alt_arqref,
                 flag_exec_alt_arqexe, tipo_termino_exec,
                 flag_pode_pular_aval, flag_aprov_refaz, flag_aprov_devolve
            FROM tipo_os
           WHERE tipo_os_id = r_tos.tipo_os_old_id;
     --
     INSERT INTO tipo_os_transicao
                (tipo_os_id, os_transicao_id)
          SELECT v_tipo_os_id, os_transicao_id
            FROM tipo_os_transicao
           WHERE tipo_os_id = r_tos.tipo_os_old_id;
   END LOOP;
   */
   --
   ------------------------------------------------------------
   -- carga de tipo de apontamento
   ------------------------------------------------------------
   INSERT INTO tipo_apontam
    (tipo_apontam_id,
     codigo,
     nome,
     empresa_id,
     flag_sistema,
     flag_ativo,
     flag_ausencia,
     flag_formulario)
    SELECT seq_tipo_apontam.nextval,
           codigo,
           nome,
           v_empresa_id,
           flag_sistema,
           flag_ativo,
           flag_ausencia,
           flag_formulario
      FROM tipo_apontam
     WHERE empresa_id = v_empresa_old_id
       AND flag_ativo = 'S';
   --
   ------------------------------------------------------------
   -- carga de tipo financeiro
   ------------------------------------------------------------
   INSERT INTO tipo_financeiro
    (tipo_financeiro_id,
     empresa_id,
     codigo,
     nome,
     tipo_custo,
     flag_padrao,
     flag_ativo)
    SELECT seq_tipo_financeiro.nextval,
           v_empresa_id,
           codigo,
           nome,
           tipo_custo,
           flag_padrao,
           flag_ativo
      FROM tipo_financeiro
     WHERE empresa_id = v_empresa_old_id
       AND flag_ativo = 'S';
   --
   ------------------------------------------------------------
   -- carga de papel
   ------------------------------------------------------------
   /*
   FOR r_pa IN c_pa LOOP
     -- verifica se a area ja existe na nova empresa
     SELECT MAX(area_id)
       INTO v_area_id
       FROM area
      WHERE empresa_id = v_empresa_id
        AND nome = r_pa.nome_area;
     --
     IF v_area_id IS NULL THEN
        -- precisa criar a area
        SELECT seq_area.NEXTVAL
          INTO v_area_id
          FROM dual;
        --
        INSERT INTO area (area_id, empresa_id, nome)
                   VALUES(v_area_id, v_empresa_id, r_pa.nome_area);
     END IF;
     --
     SELECT seq_papel.NEXTVAL
       INTO v_papel_id
       FROM dual;
     --
     INSERT INTO papel
                (papel_id, empresa_id, area_id, nome, ordem, tela_inicial,
                 flag_ender, flag_apontam_form, flag_auto_ender)
          SELECT v_papel_id, v_empresa_id, v_area_id, nome, ordem, tela_inicial,
                 flag_ender, flag_apontam_form, flag_auto_ender
            FROM papel
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_inbox
                (papel_id, inbox_id)
          SELECT v_papel_id, inbox_id
            FROM papel_inbox
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_painel
                (papel_id, painel_id)
          SELECT v_papel_id, painel_id
            FROM papel_painel
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_priv
                (papel_id, privilegio_id, abrangencia)
          SELECT v_papel_id, privilegio_id, abrangencia
            FROM papel_priv
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_priv_tpessoa
                (papel_id, privilegio_id, tipo_pessoa_id, abrangencia)
          SELECT v_papel_id, privilegio_id, tipo_pessoa_id, abrangencia
            FROM papel_priv_tpessoa
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_priv_tdoc
                (papel_id, privilegio_id, tipo_documento_id, abrangencia)
          SELECT v_papel_id, privilegio_id, tipo_documento_id, abrangencia
            FROM papel_priv_tdoc
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_priv_tos
                (papel_id, privilegio_id, tipo_os_id, abrangencia)
          SELECT v_papel_id, privilegio_id, tipo_os_id, abrangencia
            FROM papel_priv_tos
           WHERE papel_id = r_pa.papel_old_id;
     --
     INSERT INTO papel_priv_area
                (papel_id, privilegio_id, area_id, abrangencia)
          SELECT v_papel_id, privilegio_id, area_id, abrangencia
            FROM papel_priv_area
           WHERE papel_id = r_pa.papel_old_id;
     --
   END LOOP;
   */
   --
   ------------------------------------------------------------
   -- carga de tipo de produto
   ------------------------------------------------------------
   /*
   FOR r_tp IN c_tp LOOP
     v_classe_produto_id := NULL;
     --
     -- verifica se a classe ja existe na nova empresa
     IF r_tp.cod_classe IS NOT NULL THEN
        SELECT MAX(classe_produto_id)
          INTO v_classe_produto_id
          FROM classe_produto
         WHERE empresa_id = v_empresa_id
           AND cod_classe = r_tp.cod_classe
           AND NVL(sub_classe,'ZZZ') = NVL(r_tp.sub_classe,'ZZZ');
        --
        IF v_classe_produto_id IS NULL THEN
           -- precisa criar a classe
           SELECT seq_classe_produto.NEXTVAL
             INTO v_classe_produto_id
             FROM dual;
           --
           INSERT INTO classe_produto
                      (classe_produto_id, empresa_id, cod_classe, sub_classe, nome_classe)
                VALUES(v_classe_produto_id, v_empresa_id, r_tp.cod_classe, r_tp.sub_classe, r_tp.nome_classe);
        END IF;
     END IF;
     --
     SELECT seq_tipo_produto.NEXTVAL
       INTO v_tipo_produto_id
       FROM dual;
     --
     INSERT INTO tipo_produto
                (tipo_produto_id, empresa_id, classe_produto_id, nome, codigo,
                 flag_ativo, flag_sistema, variacoes,
                 tempo_exec_info, categoria )
          VALUES(v_tipo_produto_id, v_empresa_id, v_classe_produto_id, r_tp.nome, r_tp.codigo,
                 r_tp.flag_ativo, r_tp.flag_sistema, r_tp.variacoes,
                 r_tp.tempo_exec_info, r_tp.categoria);
     --
     INSERT INTO tipo_produto_var
                (tipo_produto_id, nome)
          SELECT v_tipo_produto_id, nome
            FROM tipo_produto_var
           WHERE tipo_produto_id = r_tp.tipo_produto_old_id;
   END LOOP;
   */
   --ALCBO_030725
   --Criação de classe padrão
   INSERT INTO classe_produto
    (classe_produto_id,
     empresa_id,
     cod_classe,
     nome_classe,
     sub_classe)
   VALUES
    (seq_classe_produto.nextval,
     v_empresa_id,
     'SIST',
     'Sistema',
     'Sistema');
   --
   --Criação de categoria padrão
   INSERT INTO categoria
    (categoria_id,
     empresa_id,
     descricao,
     cod_ext,
     cod_acao_os,
     tipo_entregavel,
     flag_entregue_cli,
     classe_produto_id,
     flag_tp_midia_on,
     flag_tp_midia_off,
     flag_ativo)
   VALUES
    (seq_categoria.nextval,
     v_empresa_id,
     'Principal',
     'ND',
     'CRIAR',
     'PROD',
     'S',
     10,
     NULL,
     NULL,
     'S');
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE flag_sistema = 'S'
      AND empresa_id = v_empresa_old_id;
   --
   SELECT MAX(categoria_id)
     INTO v_categoria_id
     FROM categoria
    WHERE empresa_id = v_empresa_id;
   IF v_qt = 0
   THEN
    -- carrega tipos de produto do sistema
    INSERT INTO tipo_produto
     (tipo_produto_id,
      nome,
      codigo,
      flag_ativo,
      flag_sistema,
      empresa_id,
      categoria_id,
      unidade_freq)
    VALUES
     (seq_tipo_produto.nextval,
      'CPMF',
      'CPMF',
      'S',
      'S',
      v_empresa_id,
      v_categoria_id,
      'UN');
    --
    INSERT INTO tipo_produto
     (tipo_produto_id,
      nome,
      codigo,
      flag_ativo,
      flag_sistema,
      empresa_id,
      categoria_id,
      unidade_freq)
    VALUES
     (seq_tipo_produto.nextval,
      'Honorários',
      'HONOR',
      'S',
      'S',
      v_empresa_id,
      v_categoria_id,
      'UN');
    --
    INSERT INTO tipo_produto
     (tipo_produto_id,
      nome,
      codigo,
      flag_ativo,
      flag_sistema,
      empresa_id,
      categoria_id,
      unidade_freq)
    VALUES
     (seq_tipo_produto.nextval,
      'Encargos sobre Custos',
      'ENCARGO',
      'S',
      'S',
      v_empresa_id,
      v_categoria_id,
      'UN');
    --
    INSERT INTO tipo_produto
     (tipo_produto_id,
      nome,
      codigo,
      flag_ativo,
      flag_sistema,
      empresa_id,
      categoria_id,
      unidade_freq)
    VALUES
     (seq_tipo_produto.nextval,
      'Encargos sobre Honorários',
      'ENCARGO_HONOR',
      'S',
      'S',
      v_empresa_id,
      v_categoria_id,
      'UN');
    --
    INSERT INTO tipo_produto
     (tipo_produto_id,
      codigo,
      nome,
      flag_ativo,
      flag_sistema,
      empresa_id,
      categoria_id,
      unidade_freq)
    VALUES
     (seq_tipo_produto.nextval,
      'ND',
      'Não definido',
      'S',
      'S',
      v_empresa_id,
      v_categoria_id,
      'UN');
   END IF;
   --
   ------------------------------------------------------------
   -- carga de pessoa
   ------------------------------------------------------------
   /*
   FOR r_pe IN c_pe LOOP
     v_grupo_id := NULL;
     --
     -- verifica se o grupo ja existe na nova empresa
     IF r_pe.nome_grupo IS NOT NULL THEN
        SELECT MAX(grupo_id)
          INTO v_grupo_id
          FROM grupo
         WHERE empresa_id = v_empresa_id
           AND nome = r_pe.nome_grupo;
        --
        IF v_grupo_id IS NULL THEN
           -- precisa criar o grupo
           SELECT seq_grupo.NEXTVAL
             INTO v_grupo_id
             FROM dual;
           --
           INSERT INTO grupo
                      (grupo_id, empresa_id, nome)
                VALUES(v_grupo_id, v_empresa_id, r_pe.nome_grupo);
        END IF;
     END IF;
     --
     SELECT seq_pessoa.NEXTVAL
       INTO v_pessoa_id
       FROM dual;
     --
     -- guarda no cod_ext_pessoa o pessoa_id antigo
     INSERT INTO pessoa
                 (pessoa_id, empresa_id, grupo_id,
                 fi_banco_id, apelido, nome, flag_pessoa_jur,cnpj,
                 inscr_estadual, inscr_municipal, inscr_inss, cpf,
                 rg, rg_org_exp, rg_data_exp, rg_uf, flag_sem_docum,
                 sexo, data_nasc, estado_civil, funcao, endereco,
                 num_ender, compl_ender, zona, bairro, cep, cidade,
                 uf, pais, ddd_telefone, num_telefone, ddd_fax,
                 num_fax, ddd_celular, num_celular, num_ramal,
                 website, email, num_agencia, num_conta, nome_titular,
                 cnpj_cpf_titular, tipo_conta, obs, perc_honor,
                 perc_encargo, perc_encargo_honor, num_dias_fatur,
                 tipo_num_dias_fatur, perc_bv, tipo_fatur_bv,
                 perc_imposto, desc_servicos, flag_ativo, flag_emp_resp,
                 flag_emp_fatur, valor_faixa_retencao,
                 flag_pago_cliente, flag_fornec_interno, flag_emp_incentivo,
                 latitude, longitude, flag_emp_scp, cod_ext_pessoa)
          SELECT v_pessoa_id, v_empresa_id, v_grupo_id,
                 fi_banco_id, apelido, nome, flag_pessoa_jur,cnpj,
                 inscr_estadual, inscr_municipal, inscr_inss, cpf,
                 rg, rg_org_exp, rg_data_exp, rg_uf, flag_sem_docum,
                 sexo, data_nasc, estado_civil, funcao, endereco,
                 num_ender, compl_ender, zona, bairro, cep, cidade,
                 uf, pais, ddd_telefone, num_telefone, ddd_fax,
                 num_fax, ddd_celular, num_celular, num_ramal,
                 website, email, num_agencia, num_conta, nome_titular,
                 cnpj_cpf_titular, tipo_conta, obs, perc_honor,
                 perc_encargo, perc_encargo_honor, num_dias_fatur,
                 tipo_num_dias_fatur, perc_bv, tipo_fatur_bv,
                 perc_imposto, desc_servicos, flag_ativo, flag_emp_resp,
                 flag_emp_fatur, valor_faixa_retencao,
                 flag_pago_cliente, flag_fornec_interno, flag_emp_incentivo,
                 latitude, longitude, flag_emp_scp, TO_CHAR(r_pe.pessoa_old_id)
            FROM pessoa
           WHERE pessoa_id = r_pe.pessoa_old_id;
     --
     INSERT INTO tipific_pessoa
                (pessoa_id, tipo_pessoa_id)
          SELECT v_pessoa_id, tipo_pessoa_id
            FROM tipific_pessoa
           WHERE pessoa_id = r_pe.pessoa_old_id;
     --
     INSERT INTO produto_cliente
                (produto_cliente_id, pessoa_id, nome)
          SELECT seq_produto_cliente.NEXTVAL, v_pessoa_id, nome
            FROM produto_cliente
           WHERE pessoa_id = r_pe.pessoa_old_id;
     --
     INSERT INTO natureza_oper_fatur (
                 natureza_oper_fatur_id
               , pessoa_id
               , codigo
               , descricao
               , flag_padrao
               , flag_bv
               , flag_servico
               , ordem)
          SELECT seq_natureza_oper_fatur.NEXTVAL
               , v_pessoa_id
               , codigo
               , descricao
               , flag_padrao
               , flag_bv
               , flag_servico
               , ordem
            FROM natureza_oper_fatur
           WHERE pessoa_id = r_pe.pessoa_old_id;
     --
     INSERT INTO fi_tipo_imposto_pessoa
                (fi_tipo_imposto_pessoa_id, pessoa_id, fi_tipo_imposto_id,
                 nome_servico, perc_imposto, flag_reter)
          SELECT seq_fi_tipo_imposto_pessoa.NEXTVAL, v_pessoa_id, fi_tipo_imposto_id,
                 nome_servico, perc_imposto, flag_reter
            FROM fi_tipo_imposto_pessoa
           WHERE pessoa_id = r_pe.pessoa_old_id;
   END LOOP;
   --
   ------------------------------------------------------------
   -- carga das relacoes (contatos)
   ------------------------------------------------------------
   FOR r_re IN c_re LOOP
     INSERT INTO relacao (pessoa_pai_id, pessoa_filho_id)
                  VALUES (r_re.pessoa_pai_id, r_re.pessoa_filho_id);
   END LOOP;
   --
   -- limpa o campo cod_ext_pessoa usado para guardar o ID antigo
   UPDATE pessoa
      SET cod_ext_pessoa = NULL
    WHERE empresa_id = v_empresa_id;
    */
   --
  END IF; -- fim do IF v_empresa_old_id IS NOT NULL
  --
  ------------------------------------------------------------
  -- libera acesso a nova empresa para o admin
  ------------------------------------------------------------
  INSERT INTO usuario_empresa
   (usuario_id,
    empresa_id,
    flag_padrao)
  VALUES
   (p_usuario_sessao_id,
    v_empresa_id,
    'N');
  --
  ------------------------------------------------------------
  -- carga notificacao padrao (executar apos carga tipos OS)
  ------------------------------------------------------------
  evento_pkg.carregar;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(v_empresa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome) || ' - ' || TRIM(p_codigo);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_id,
                   'EMPRESA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_empresa_id,
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
  p_empresa_id := v_empresa_id;
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 24/05/2010
  -- DESCRICAO: Atualizacao de EMPRESA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/06/2017  Novos atributos pais e localidade
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN empresa.nome%TYPE,
  p_codigo            IN empresa.codigo%TYPE,
  p_cod_ext_empresa   IN empresa.cod_ext_empresa%TYPE,
  p_pais_id           IN pais.pais_id%TYPE,
  p_localidade        IN VARCHAR2,
  p_flag_ativo        IN empresa.flag_ativo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id
     AND flag_admin = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa não existe.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_codigo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id <> p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id <> p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE upper(cod_ext_empresa) = TRIM(upper(p_cod_ext_empresa))
     AND empresa_id <> p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código externo de empresa já existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_pais_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do país é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pais
   WHERE pais_id = p_pais_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse país não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_localidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da localidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('localidade', p_localidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Localidade inválida (' || p_localidade || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(p_empresa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE empresa
     SET nome            = TRIM(p_nome),
         codigo          = TRIM(p_codigo),
         cod_ext_empresa = TRIM(p_cod_ext_empresa),
         flag_ativo      = p_flag_ativo,
         pais_id         = zvl(p_pais_id, NULL),
         localidade      = TRIM(p_localidade)
   WHERE empresa_id = p_empresa_id;
  --
  -- carrega eventuais parametros ainda nao carregados com valor padrao
  INSERT INTO empresa_parametro
   (empresa_id,
    parametro_id,
    valor)
   SELECT p_empresa_id,
          parametro_id,
          valor
     FROM parametro pa
    WHERE NOT EXISTS (SELECT 1
             FROM empresa_parametro ep
            WHERE ep.empresa_id = p_empresa_id
              AND ep.parametro_id = pa.parametro_id);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(p_empresa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome) || ' - ' || TRIM(p_codigo);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EMPRESA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_empresa_id,
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 24/05/2010
  -- DESCRICAO: Exclusao de EMPRESA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/02/2010  Consistencia de area.
  -- Silvia            10/02/2011  Consistencia de usuario_painel
  -- Silvia            12/12/2013  Exclusao de faixa_aprov
  -- Silvia            21/03/2016  Exclusao de status_aux_job
  -- Silvia            12/09/2016  Exclusao de natureza_item
  -- Silvia            22/09/2016  Consistencia de departamento/cargo
  -- Silvia            15/06/2018  Consistencia de produto_fiscal
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            26/02/2019  Consistencia de setor e servico
  -- Silvia            28/02/2019  Consistencia de oportunidade e exclusao status_aux_oport
  -- Silvia            03/12/2019  Consistencia de equipe.
  -- Silvia            04/02/2021  Exclusao de condicao_pagto_dia
  -- Silvia            19/07/2021  Exclusao de quadro
  -- Ana Luiza         03/07/2025  Exclusao classe_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           empresa.nome%TYPE;
  v_codigo         empresa.codigo%TYPE;
  v_empresa_aux_id empresa.empresa_id%TYPE;
  v_xml_atual      CLOB;
  v_lbl_jobs       VARCHAR2(100);
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id
     AND flag_admin = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         codigo
    INTO v_nome,
         v_codigo
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  -- recupera o ID de uma outra empresa para registrar no historico
  SELECT MIN(empresa_id)
    INTO v_empresa_aux_id
    FROM empresa
   WHERE empresa_id <> p_empresa_id
     AND flag_ativo = 'S';
  --
  IF v_empresa_aux_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Deve existir pelo menos uma outra empresa ativa.';
   RAISE v_exception;
  END IF;
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem pessoas relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem usuários relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem papéis relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM grupo
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem grupos de pessoas relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem equipes de usuários relacionadas a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Tasks relacionadas a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem tasks relacionadas a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem eventos (milestones) relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM area
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem áreas relacionadas a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM metadado
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem metadados relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora ah,
         tipo_apontam ti
   WHERE ti.empresa_id = p_empresa_id
     AND ti.tipo_apontam_id = ah.tipo_apontam_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de horas relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo      ar,
         tipo_arquivo ti
   WHERE ti.empresa_id = p_empresa_id
     AND ti.tipo_arquivo_id = ar.tipo_arquivo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem modelos de cronograma relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM departamento
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem departamentos relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cargos relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem bancos relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_fiscal
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem produtos fiscais relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM setor
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem setores relacionados a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE empresa_id = p_empresa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem oportunidades relacionadas a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(p_empresa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  DELETE FROM pessoa_transferencia
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM ctx_arquivo
   WHERE empresa_id = p_empresa_id;
  --ALCBO_030725
  DELETE FROM classe_produto
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM categoria
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_job
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_contrato
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_financeiro
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_os_transicao tt
   WHERE EXISTS (SELECT 1
            FROM tipo_os ti
           WHERE ti.empresa_id = p_empresa_id
             AND ti.tipo_os_id = tt.tipo_os_id);
  --
  DELETE FROM tipo_prod_tipo_os tt
   WHERE EXISTS (SELECT 1
            FROM tipo_os ti
           WHERE ti.empresa_id = p_empresa_id
             AND ti.tipo_os_id = tt.tipo_os_id);
  --
  DELETE FROM tipo_os
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM condicao_pagto_det cd
   WHERE EXISTS (SELECT 1
            FROM condicao_pagto co
           WHERE co.empresa_id = p_empresa_id
             AND co.condicao_pagto_id = cd.condicao_pagto_id);
  --
  DELETE FROM condicao_pagto_dia cd
   WHERE EXISTS (SELECT 1
            FROM condicao_pagto co
           WHERE co.empresa_id = p_empresa_id
             AND co.condicao_pagto_id = cd.condicao_pagto_id);
  --
  DELETE FROM tipo_produto_var tv
   WHERE EXISTS (SELECT 1
            FROM tipo_produto tp
           WHERE tp.empresa_id = p_empresa_id
             AND tp.tipo_produto_id = tv.tipo_produto_id);
  --
  DELETE FROM notifica_config nc
   WHERE EXISTS (SELECT 1
            FROM evento_config ev
           WHERE ev.empresa_id = p_empresa_id
             AND ev.evento_config_id = nc.evento_config_id);
  --
  DELETE FROM faixa_aprov_papel fp
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.empresa_id = p_empresa_id
             AND fa.faixa_aprov_id = fp.faixa_aprov_id);
  --
  DELETE FROM faixa_aprov_ao fp
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.empresa_id = p_empresa_id
             AND fa.faixa_aprov_id = fp.faixa_aprov_id);
  --
  DELETE FROM faixa_aprov_os fp
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.empresa_id = p_empresa_id
             AND fa.faixa_aprov_id = fp.faixa_aprov_id);
  --
  DELETE FROM faixa_aprov
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM evento_config
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM condicao_pagto
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM feriado fe
   WHERE EXISTS (SELECT 1
            FROM tab_feriado tf
           WHERE empresa_id = p_empresa_id
             AND fe.tab_feriado_id = tf.tab_feriado_id);
  --
  DELETE FROM tab_feriado
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM natureza_item_inc nc
   WHERE EXISTS (SELECT 1
            FROM natureza_item ni
           WHERE ni.empresa_id = p_empresa_id
             AND ni.natureza_item_id = nc.natureza_item_id);
  --
  DELETE FROM natureza_item
   WHERE empresa_id = p_empresa_id;
  --
  /*
  DELETE FROM dicion_emp_val dv
   WHERE EXISTS (SELECT 1
            FROM dicion_emp di
           WHERE di.empresa_id = p_empresa_id
             AND di.dicion_emp_id = dv.dicion_emp_id);
   */
  --
  /*
  DELETE FROM dicion_emp
   WHERE empresa_id = p_empresa_id;
  */
  --
  --
  DELETE FROM quadro_os_config qo
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc,
                 quadro        qd
           WHERE qd.empresa_id = p_empresa_id
             AND qc.quadro_id = qc.quadro_id
             AND qc.quadro_coluna_id = qo.quadro_coluna_id);
  DELETE FROM quadro_tarefa_config qt
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc,
                 quadro        qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qc.quadro_id
             AND qc.quadro_coluna_id = qt.quadro_coluna_id);
  DELETE FROM quadro_coluna qc
   WHERE EXISTS (SELECT 1
            FROM quadro qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qc.quadro_id);
  DELETE FROM quadro_equipe qe
   WHERE EXISTS (SELECT 1
            FROM quadro qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qe.quadro_id);
  DELETE FROM quadro
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM papel_painel pp
   WHERE EXISTS (SELECT 1
            FROM painel pa
           WHERE pa.empresa_id = p_empresa_id);
  DELETE FROM painel
   WHERE empresa_id = p_empresa_id;
  --
  --
  DELETE FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_apontam
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_apontam_job
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_produto
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_documento
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_tarefa
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM classe_produto
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM status_aux_job
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM status_aux_oport
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM historico
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM empresa_parametro
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM padrao_planilha
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM notifica_desliga
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM sist_ext_ponto_int
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM sist_ext_ponto_int
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM empresa_sist_ext
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM pesquisa
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM apontam_ence
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_nome) || ' - ' || TRIM(v_codigo);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_aux_id,
                   'EMPRESA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_empresa_id,
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
 END excluir;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 11/07/2016
  -- DESCRICAO: Adicionar arquivo na empresa.
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
  p_empresa_arq_id    IN arquivo_empresa.empresa_id%TYPE,
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
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_nome            empresa.nome%TYPE;
  v_codigo          empresa.codigo%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_arq_id;
  --
  IF v_qt = 0then p_erro_cod := '90000' ; p_erro_msg := 'Essa empresa não existe.' ; RAISE
   v_exception ; END IF ;
  --
   SELECT COUNT(*)
       INTO v_qt
       FROM usuario
      WHERE usuario_id = p_usuario_sessao_id
        AND flag_admin = 'S';
     --
     IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         codigo
    INTO v_nome,
         v_codigo
    FROM empresa
   WHERE empresa_id = p_empresa_id;
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
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_arq_id
     AND codigo = 'EMPRESA';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_empresa_arq_id,
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
  v_identif_objeto := TRIM(v_nome) || ' - ' || TRIM(v_codigo);
  --
  v_compl_histor := 'Anexação de arquivo na empresa (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EMPRESA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_empresa_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 11/07/2016
  -- DESCRICAO: Excluir arquivo da empresa
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
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome_original  arquivo.nome_original%TYPE;
  v_nome           empresa.nome%TYPE;
  v_codigo         empresa.codigo%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa         em,
         arquivo_empresa ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.empresa_id = em.empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id
     AND flag_admin = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         codigo
    INTO v_nome,
         v_codigo
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  SELECT ar.nome_original
    INTO v_nome_original
    FROM arquivo ar
   WHERE ar.arquivo_id = p_arquivo_id;
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
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_nome) || ' - ' || TRIM(v_codigo);
  v_compl_histor   := 'Exclusão de arquivo da empresa (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EMPRESA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_empresa_id,
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
 PROCEDURE parametro_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 12/04/2010
  -- DESCRICAO: Atualização de parametro da empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa_parametro.empresa_id%TYPE,
  p_parametro_id      IN empresa_parametro.parametro_id%TYPE,
  p_valor_parametro   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_exception      EXCEPTION;
  v_nome_param     parametro.nome%TYPE;
  v_nome           empresa.nome%TYPE;
  v_codigo         empresa.codigo%TYPE;
  --
  CURSOR c_st IS
   SELECT codigo    AS cod_status,
          descricao AS nome_status
     FROM dicionario
    WHERE tipo = 'status_job'
    ORDER BY ordem;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id
     AND flag_admin = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido ou sem permissão.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_valor_parametro) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor do parâmetro é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_param
    FROM parametro
   WHERE parametro_id = p_parametro_id;
  --
  SELECT nome,
         codigo
    INTO v_nome,
         v_codigo
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(p_empresa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa_parametro
   WHERE empresa_id = p_empresa_id
     AND parametro_id = p_parametro_id;
  --
  IF v_qt = 0
  THEN
   INSERT INTO empresa_parametro
    (empresa_id,
     parametro_id)
   VALUES
    (p_empresa_id,
     p_parametro_id);
  ELSE
   UPDATE empresa_parametro
      SET valor = p_valor_parametro
    WHERE empresa_id = p_empresa_id
      AND parametro_id = p_parametro_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes especificas
  ------------------------------------------------------------
  IF v_nome_param = 'USAR_STATUS_AUX_JOB' AND p_valor_parametro = 'S'
  THEN
   -- verifica se p/ cada status principal do job existe pelo menos 1
   -- status estendido.
   FOR r_st IN c_st
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM status_aux_job
     WHERE empresa_id = p_empresa_id
       AND cod_status_pai = r_st.cod_status;
    --
    IF v_qt = 0
    THEN
     INSERT INTO status_aux_job
      (status_aux_job_id,
       empresa_id,
       cod_status_pai,
       nome,
       ordem,
       flag_padrao,
       flag_ativo)
     VALUES
      (seq_status_aux_job.nextval,
       p_empresa_id,
       r_st.cod_status,
       r_st.nome_status,
       1,
       'S',
       'S');
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  empresa_pkg.xml_gerar(p_empresa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_nome) || ' - ' || TRIM(v_codigo);
  v_compl_histor   := 'Atualização de parâmetro (' || v_nome_param || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EMPRESA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_empresa_id,
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
 END parametro_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/04/2017
  -- DESCRICAO: Subrotina que gera o xml da empresa para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_empresa_id IN empresa.empresa_id%TYPE,
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
  CURSOR c_pa IS
   SELECT pa.nome,
          pa.descricao,
          ep.valor,
          pa.grupo
     FROM empresa_parametro ep,
          parametro         pa
    WHERE ep.empresa_id = p_empresa_id
      AND ep.parametro_id = pa.parametro_id
    ORDER BY pa.grupo,
             pa.ordem;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("empresa_id", em.empresa_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", em.nome),
                   xmlelement("codigo", em.codigo),
                   xmlelement("servidor_arquivo_nome", sa.nome),
                   xmlelement("servidor_arquivo_ender", sa.endereco),
                   xmlelement("ativo", em.flag_ativo),
                   xmlelement("cod_ext_empresa", em.cod_ext_empresa))
    INTO v_xml
    FROM empresa          em,
         servidor_arquivo sa
   WHERE em.empresa_id = p_empresa_id
     AND em.servidor_arquivo_id = sa.servidor_arquivo_id(+);
  --
  ------------------------------------------------------------
  -- monta PARAMETROS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlagg(xmlelement("parametro",
                            xmlelement("grupo", r_pa.grupo),
                            xmlelement("codigo", r_pa.nome),
                            xmlelement("descricao", r_pa.descricao),
                            xmlelement("valor", r_pa.valor)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("parametros", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "empresa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("empresa", v_xml))
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
 FUNCTION parametro_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2010
  -- DESCRICAO: retorna o valor do parametro especificado para uma determinada empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id     IN empresa.empresa_id%TYPE,
  p_nome_parametro IN parametro.nome%TYPE
 ) RETURN VARCHAR2 AS
  v_valor     parametro.valor%TYPE;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_valor := NULL;
  --
  SELECT MAX(ep.valor)
    INTO v_valor
    FROM empresa_parametro ep,
         parametro         pa
   WHERE ep.empresa_id = p_empresa_id
     AND ep.parametro_id = pa.parametro_id
     AND upper(pa.nome) = upper(p_nome_parametro);
  --
  IF v_valor IS NULL
  THEN
   SELECT MAX(pa.valor)
     INTO v_valor
     FROM parametro pa
    WHERE upper(pa.nome) = upper(p_nome_parametro);
  END IF;
  --
  RETURN v_valor;
 EXCEPTION
  WHEN OTHERS THEN
   v_valor := 'ERRO';
   RETURN v_valor;
 END parametro_retornar;
 --
 --
 FUNCTION servidor_arquivo_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/07/2013
  -- DESCRICAO: retorna o servidor de arquivos padrao de uma determinada empresa. Caso o
  --  parametro job_id seja fornecido, procura pelo servidor de arquivos definido para
  --  a empresa responsavel pelo job, se houver.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_job_id     IN job.job_id%TYPE
 ) RETURN NUMBER AS
  v_servidor_arquivo_id servidor_arquivo.servidor_arquivo_id%TYPE;
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  --
 BEGIN
  v_servidor_arquivo_id := NULL;
  --
  IF nvl(p_job_id, 0) > 0
  THEN
   SELECT MAX(se.servidor_arquivo_id)
     INTO v_servidor_arquivo_id
     FROM job         jo,
          sa_emp_resp se
    WHERE jo.job_id = p_job_id
      AND jo.empresa_id = p_empresa_id
      AND jo.emp_resp_id = se.pessoa_id;
  END IF;
  --
  IF v_servidor_arquivo_id IS NULL
  THEN
   SELECT MAX(servidor_arquivo_id)
     INTO v_servidor_arquivo_id
     FROM empresa
    WHERE empresa_id = p_empresa_id;
  END IF;
  --
  RETURN v_servidor_arquivo_id;
 EXCEPTION
  WHEN OTHERS THEN
   v_servidor_arquivo_id := NULL;
   RETURN v_servidor_arquivo_id;
 END servidor_arquivo_retornar;
 --
END; -- empresa_pkg

/
