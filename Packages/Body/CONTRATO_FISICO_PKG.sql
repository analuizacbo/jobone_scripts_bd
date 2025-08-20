--------------------------------------------------------
--  DDL for Package Body CONTRATO_FISICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CONTRATO_FISICO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Jos� Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Adiciona novo registro de contrato f�sico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_prazo        IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_numero_contrato       contrato.numero%TYPE;
  v_status_contrato       contrato.status%TYPE;
  v_contrato_fisico_id    contrato_fisico.contrato_fisico_id%TYPE;
  v_data_elab             contrato_fisico.data_elab%TYPE;
  v_data_prazo            contrato_fisico.data_prazo%TYPE;
  v_exception             EXCEPTION;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_xml_atual             CLOB;
  v_num_dias_apro_ctr_fis NUMBER(10);
  v_versao                contrato_fisico.versao%TYPE;
  v_desc_status           VARCHAR(100);
 BEGIN
  v_data_elab := trunc(SYSDATE);
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
   p_erro_msg := 'Esse contrato n�o existe ou n�o pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato n�o permite essa opera��o.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inv�lido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_usuario_sessao_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usu�rio inv�lido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo inv�lida.';
   RAISE v_exception;
  END IF;
  --
  v_data_prazo := data_converter(p_data_prazo);
  --
  IF v_data_prazo IS NULL THEN
   v_num_dias_apro_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_ELAB_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_apro_ctr_fis,
                                                                 'N');
  END IF;
  --
  IF v_data_elab > v_data_prazo THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                 data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

   RAISE v_exception;
  END IF;
  --
  SELECT nvl(MAX(versao), 0) + 1
    INTO v_versao
    FROM contrato_fisico
   WHERE contrato_id = p_contrato_id;
  --
  SELECT seq_contrato_fisico.nextval
    INTO v_contrato_fisico_id
    FROM dual;

  INSERT INTO contrato_fisico
   (contrato_fisico_id,
    contrato_id,
    usuario_elab_id,
    usuario_motivo_id,
    versao,
    status,
    descricao,
    data_prazo,
    data_elab,
    motivo,
    data_motivo)
  VALUES
   (v_contrato_fisico_id,
    p_contrato_id,
    p_usuario_sessao_id,
    NULL,
    v_versao,
    'PEND',
    NULL,
    v_data_prazo,
    v_data_elab,
    NULL,
    NULL);
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
  v_identif_objeto := contrato_pkg.numero_formatar(p_contrato_id);
  v_compl_histor   := 'Inclus�o de contrato jur�dico vers�o ' || to_char(v_versao);
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
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
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
 PROCEDURE desc_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Jos� Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Atualiza descricao do contrato fisico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_descricao          IN contrato_fisico.descricao%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_contrato_fisico_id contrato_fisico.contrato_fisico_id%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_xml_atual          CLOB;
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(1)
    INTO v_qt
    FROM contrato_fisico
   WHERE contrato_fisico_id = p_contrato_fisico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato jur�dico n�o existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descri��o � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE contrato_fisico
     SET descricao = TRIM(p_descricao)
   WHERE contrato_fisico_id = p_contrato_fisico_id;
  --
  COMMIT;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END desc_atualizar;
 --
 --
 PROCEDURE acao_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Jos� Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Executa transicao de status do contrato fisico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/10/2022  Atualizacao do registro FISI em contrato_elab
  -- Ana Luiza         15/09/2023  Atualiza flag da tab contrato.
  -- Ana Luiza         16/12/2024  Grava linha para alteracao de status
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_cod_acao           IN ct_transicao.cod_acao%TYPE,
  p_descricao          IN contrato_fisico.descricao%TYPE,
  p_motivo             IN contrato_fisico.motivo%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_contrato_id           contrato_fisico.contrato_id%TYPE;
  v_xml_atual             CLOB;
  v_usuario_elab_id       contrato_fisico.usuario_elab_id%TYPE;
  v_usuario_motivo_id     contrato_fisico.usuario_motivo_id%TYPE;
  v_versao                contrato_fisico.versao%TYPE;
  v_status_de             contrato_fisico.status%TYPE;
  v_status_para           ct_transicao.status_para%TYPE;
  v_descricao             contrato_fisico.descricao%TYPE;
  v_data_prazo            contrato_fisico.data_prazo%TYPE;
  v_data_elab             contrato_fisico.data_elab%TYPE;
  v_motivo                contrato_fisico.motivo%TYPE;
  v_data_motivo           contrato_fisico.data_motivo%TYPE;
  v_num_dias_revi_ctr_fis NUMBER(10);
  v_num_dias_apro_ctr_fis NUMBER(10);
  v_num_dias_assi_ctr_fis NUMBER(10);
  v_num_dias_reca_ctr_fis NUMBER(10);
  v_num_dias_elab_ctr_fis NUMBER(10);
  v_flag_nova_versao      ct_transicao.flag_nova_versao%TYPE;
  v_arquivo_id            arquivo_contrato_fisico.arquivo_id%TYPE;
  v_desc_status_de        VARCHAR(100);
  v_desc_status_para      VARCHAR(100);
  --ALCBO_150923
  v_flag_assinatura contrato.flag_assinado%TYPE;
  v_data_assinatura contrato.data_assinatura%TYPE;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT COUNT(1)
    INTO v_qt
    FROM contrato_fisico
   WHERE contrato_fisico_id = p_contrato_fisico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato jur�dico n�o existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inv�lido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ct_transicao
   WHERE cod_objeto = 'CONTRATO_FISICO'
     AND cod_acao = p_cod_acao;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'C�digo de a��o de contrato jur�dico inv�lido ' || p_cod_acao || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT contrato_id,
         status,
         data_prazo,
         data_elab,
         versao,
         util_pkg.desc_retornar('status_contrato_fisico', status)
    INTO v_contrato_id,
         v_status_de,
         v_data_prazo,
         v_data_elab,
         v_versao,
         v_desc_status_de
    FROM contrato_fisico
   WHERE contrato_fisico_id = p_contrato_fisico_id;
  --
  IF p_cod_acao IN ('APROVAR', 'REPROVAR') THEN
   --
   IF TRIM(p_motivo) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de a��o, o preenchimento do coment�rio � obrigat�rio.';
    RAISE v_exception;
   END IF;
   --
   v_usuario_motivo_id := p_usuario_sessao_id;
   v_data_motivo       := SYSDATE;
  END IF;
  --
  SELECT MAX(status_para),
         MAX(flag_nova_versao)
    INTO v_status_para,
         v_flag_nova_versao
    FROM ct_transicao
   WHERE cod_acao = p_cod_acao
     AND status_de = v_status_de
     AND cod_objeto = 'CONTRATO_FISICO';
  --
  IF v_status_para IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transi��o inv�lida de CONTRATO FISICO (' || v_status_de || ' - ' || p_cod_acao || ')';
   RAISE v_exception;
  END IF;
  --
  SELECT util_pkg.desc_retornar('status_contrato_fisico', v_status_para)
    INTO v_desc_status_para
    FROM dual;
  --
  IF p_cod_acao = 'ENVIAR' THEN
   v_num_dias_apro_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_APRO_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_apro_ctr_fis,
                                                                 'N');
   --
   IF v_data_elab > v_data_prazo THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                  data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

    RAISE v_exception;
   END IF;
   --
   v_motivo            := NULL;
   v_usuario_motivo_id := NULL;
   --
  ELSIF p_cod_acao = 'APROVAR' THEN
   v_num_dias_apro_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_REC_ASS_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_apro_ctr_fis,
                                                                 'N');
   --
   IF v_data_elab > v_data_prazo THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                  data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

    RAISE v_exception;
   END IF;
   --
   v_motivo := p_motivo;
   --
  ELSIF p_cod_acao = 'REPROVAR' THEN
   v_num_dias_reca_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_REC_ASS_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_reca_ctr_fis,
                                                                 'N');
   --
   IF v_data_elab > v_data_prazo THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                  data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

    RAISE v_exception;
   END IF;
   --
   v_motivo := p_motivo;
   --
  ELSIF p_cod_acao = 'CANCELAR' THEN
   --ALCBO_150923
   v_flag_assinatura := 'N';
   v_data_assinatura := NULL;
   IF v_status_de = 'PEND' THEN
    DELETE FROM contrato_fisico
     WHERE contrato_fisico_id = p_contrato_fisico_id;

   ELSIF v_status_de IN ('APRO', 'REPR', 'FASS', 'EMAP', 'PASS') THEN
    v_usuario_motivo_id := NULL;
    v_motivo            := NULL;
    v_data_motivo       := NULL;
    --
    SELECT MAX(arquivo_id)
      INTO v_arquivo_id
      FROM arquivo_contrato_fisico
     WHERE contrato_fisico_id = p_contrato_fisico_id
       AND tipo_arq_fisico = 'MOTIVO';
    --
    IF v_arquivo_id IS NOT NULL THEN
     contrato_fisico_pkg.arquivo_excluir(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_arquivo_id,
                                         p_erro_cod,
                                         p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF v_status_de = 'APRO' THEN
     v_num_dias_apro_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_DIAS_REC_ASS_CTR_FIS'));
     v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                   v_data_elab,
                                                                   v_num_dias_apro_ctr_fis,
                                                                   'N');
    ELSIF v_status_de = 'EMAP' THEN
     v_num_dias_apro_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_DIAS_APRO_CTR_FIS'));
     v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                   v_data_elab,
                                                                   v_num_dias_apro_ctr_fis,
                                                                   'N');
    ELSIF v_status_de = 'REPR' THEN
     v_num_dias_reca_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_DIAS_REC_ASS_CTR_FIS'));
     v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                   v_data_elab,
                                                                   v_num_dias_reca_ctr_fis,
                                                                   'N');
    ELSIF v_status_de = 'PASS' THEN
     v_num_dias_assi_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_DIAS_ASSI_CTR_FIS'));
     v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                   v_data_elab,
                                                                   v_num_dias_assi_ctr_fis,
                                                                   'N');
    END IF;
    --
    IF v_data_elab > v_data_prazo THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                   data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

     RAISE v_exception;
    END IF;

   END IF;

  ELSIF p_cod_acao = 'AGUARDAR_ASSINATURA' THEN
   v_num_dias_assi_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_ASSI_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_assi_ctr_fis,
                                                                 'N');
   --
   IF v_data_elab > v_data_prazo THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de in�cio n�o pode ser maior que a data de t�rmino (' ||
                  data_mostrar(v_data_elab) || ' - ' || data_mostrar(v_data_prazo) || ').';

    RAISE v_exception;
   END IF;
   --
   v_motivo := p_motivo;
   --
  ELSIF p_cod_acao = 'NAO_ASSINAR' THEN
   v_data_prazo := trunc(SYSDATE);
   v_motivo     := p_motivo;
   --ALCBO_150923
   v_flag_assinatura := 'N';
   v_data_assinatura := NULL;
   --
  ELSIF p_cod_acao = 'NOVA_VERSAO' THEN
   v_data_elab             := trunc(SYSDATE);
   v_num_dias_revi_ctr_fis := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_REVI_CTR_FIS'));
   v_data_prazo            := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                 v_data_elab,
                                                                 v_num_dias_revi_ctr_fis,
                                                                 'N');
  ELSIF p_cod_acao = 'ASSINAR' THEN
   v_data_prazo := trunc(SYSDATE);
   v_motivo     := p_motivo;
   --ALCBO_150923
   v_flag_assinatura := 'S';
   v_data_assinatura := SYSDATE;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_150923
  IF v_flag_assinatura IS NOT NULL THEN
   UPDATE contrato
      SET flag_assinado   = v_flag_assinatura,
          data_assinatura = v_data_assinatura
    WHERE contrato_id = v_contrato_id;

  END IF;
  --
  IF v_flag_nova_versao = 'N' THEN
   --ALCBO_161224
   SELECT versao,
          usuario_elab_id
     INTO v_versao,
          v_usuario_elab_id
     FROM contrato_fisico
    WHERE contrato_fisico_id = p_contrato_fisico_id;
   -- hist�rico de status:
   --
   INSERT INTO contrato_fisico
    (contrato_fisico_id,
     contrato_id,
     usuario_elab_id,
     usuario_motivo_id,
     status,
     descricao,
     versao,
     motivo,
     data_motivo,
     data_prazo,
     data_elab)
   VALUES
    (seq_contrato_fisico.nextval,
     v_contrato_id,
     v_usuario_elab_id,
     v_usuario_motivo_id,
     v_status_para,
     p_descricao,
     v_versao,
     v_motivo,
     v_data_motivo,
     v_data_prazo,
     v_data_elab);
   /* UPDATE contrato_fisico c
     SET c.status            = v_status_para,
         c.descricao         = p_descricao,
         c.usuario_motivo_id = v_usuario_motivo_id,
         c.motivo            = v_motivo,
         c.data_motivo       = v_data_motivo,
         c.data_prazo        = v_data_prazo
   WHERE contrato_fisico_id = p_contrato_fisico_id;*/
   --
   IF v_status_para IN ('FASS', 'NASS') THEN
    -- terminou o processo de assinatura (feito ou nao assinado).
    -- atualiza eventual registro do fisico em contrato_elab
    UPDATE contrato_elab
       SET status        = 'PRON',
           data_execucao = SYSDATE,
           usuario_id    = p_usuario_sessao_id
     WHERE contrato_id = v_contrato_id
       AND cod_contrato_elab = 'FISI';

   ELSE
    -- atualiza eventual registro do fisico em contrato_elab
    -- como pendente.
    UPDATE contrato_elab
       SET status        = 'PEND',
           data_execucao = NULL,
           usuario_id    = p_usuario_sessao_id
     WHERE contrato_id = v_contrato_id
       AND cod_contrato_elab = 'FISI';

   END IF;

  ELSE
   contrato_fisico_pkg.adicionar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_contrato_id,
                                 data_mostrar(v_data_prazo),
                                 'N',
                                 p_erro_cod,
                                 p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
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
  v_identif_objeto := contrato_pkg.numero_formatar(v_contrato_id);
  v_compl_histor   := 'Transicao de contrato jur�dico vers�o ' || to_char(v_versao) || ' (de: ' ||
                      v_desc_status_de || ' para: ' || v_desc_status_para || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_contrato_id,
                   v_compl_histor,
                   v_motivo,
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
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END acao_executar;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Jos� Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Adiciona arquivo contrato f�sico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN NUMBER,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_tipo_arq_fisico    IN arquivo_contrato_fisico.tipo_arq_fisico%TYPE,
  p_arquivo_id         IN arquivo.arquivo_id%TYPE,
  p_volume_id          IN arquivo.volume_id%TYPE,
  p_descricao          IN arquivo.descricao%TYPE,
  p_nome_original      IN arquivo.nome_original%TYPE,
  p_nome_fisico        IN arquivo.nome_fisico%TYPE,
  p_mime_type          IN arquivo.mime_type%TYPE,
  p_tamanho            IN arquivo.tamanho%TYPE,
  p_palavras_chave     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_contrato_id     contrato.contrato_id%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_fisico
   WHERE contrato_fisico_id = p_contrato_fisico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Contrato jur�dico n�o existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_arq_fisico) NOT IN ('REFERENCIA', 'CONTRATO', 'MOTIVO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de arquivo jur�dico � inv�lido.';
   RAISE v_exception;
  END IF;
  --
  SELECT ct.numero,
         ct.contrato_id
    INTO v_numero_contrato,
         v_contrato_id
    FROM contrato_fisico cf,
         contrato        ct
   WHERE cf.contrato_fisico_id = p_contrato_fisico_id
     AND cf.contrato_id = ct.contrato_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descri��o n�o pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo � obrigat�rio.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome jur�dico do arquivo � obrigat�rio.';
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
     AND codigo = 'CONTRATO_FISICO';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_contrato_fisico_id,
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
  UPDATE arquivo_contrato_fisico
     SET tipo_arq_fisico = TRIM(p_tipo_arq_fisico)
   WHERE arquivo_id = p_arquivo_id
     AND contrato_fisico_id = p_contrato_fisico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_contrato);
  --
  v_compl_histor := 'Anexa��o de arquivo no Contrato Jur�dico (' || p_nome_original || ')';
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
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 13/06/2022
  -- DESCRICAO: Excluir arquivo do CONTRATO_FISICO
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
    FROM contrato_fisico         cf,
         arquivo_contrato_fisico ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.contrato_fisico_id = cf.contrato_fisico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo n�o existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT cf.contrato_id,
         ar.nome_original
    INTO v_contrato_id,
         v_nome_original
    FROM arquivo_contrato_fisico ac,
         arquivo                 ar,
         contrato_fisico         cf
   WHERE ac.arquivo_id = p_arquivo_id
     AND ac.arquivo_id = ar.arquivo_id
     AND ac.contrato_fisico_id = cf.contrato_fisico_id;
  --
  SELECT numero,
         status
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = v_contrato_id;
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
  v_compl_histor := 'Exclus�o de arquivo do Contrato Jur�dico (' || v_nome_original || ')';
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
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
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
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Jos� Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Exclus�o de CONTRATO_FISICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_numero_contrato    contrato.numero%TYPE;
  v_status_contrato    contrato.status%TYPE;
  v_versao             contrato_fisico.versao%TYPE;
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_contrato_fisico_id contrato_fisico.contrato_fisico_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especifica��o da empresa � obrigat�ria.';
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
   p_erro_msg := 'Esse contrato n�o existe ou n�o pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
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
   p_erro_msg := 'Esse contrato n�o existe ou n�o pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(versao)
    INTO v_versao
    FROM contrato_fisico
   WHERE contrato_id = p_contrato_id;
  --
  IF v_versao IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa vers�o de contrato jur�dico n�o existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT contrato_fisico_id
    INTO v_contrato_fisico_id
    FROM contrato_fisico
   WHERE contrato_id = p_contrato_id
     AND versao = v_versao;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  contrato_pkg.xml_gerar(p_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM arquivo_contrato_fisico
   WHERE contrato_fisico_id = v_contrato_fisico_id;
  --
  DELETE FROM contrato_fisico
   WHERE contrato_id = p_contrato_id
     AND versao = v_versao;
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
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Opera��o realizada com sucesso.';
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
END; -- CONTRATO_FISICO_PKG


/
