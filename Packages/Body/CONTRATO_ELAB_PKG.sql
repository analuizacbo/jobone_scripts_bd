--------------------------------------------------------
--  DDL for Package Body CONTRATO_ELAB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CONTRATO_ELAB_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: José Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Inclusão de CONTRATO_ELAB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/01/2023  Aceita cod_contrato_elab passado de forma
  --                               especifica, mesmo nao configurado no tipo_contrato
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN contrato.empresa_id%TYPE,
        p_contrato_id       IN contrato.contrato_id%TYPE,
        p_cod_contrato_elab IN contrato_elab.cod_contrato_elab%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                      INTEGER;
        v_exception EXCEPTION;
        v_tipo_contrato_id        contrato.tipo_contrato_id%TYPE;
        v_flag_ctr_fisico         contrato.flag_ctr_fisico%TYPE;
        v_contrato_elab_id        contrato_elab.contrato_elab_id%TYPE;
        v_status                  contrato_elab.status%TYPE;
        v_pessoa_id               pessoa.pessoa_id%TYPE;
        v_flag_verifi_precif      tipo_contrato.flag_verifi_precif%TYPE;
        v_flag_verifi_horas       tipo_contrato.flag_verifi_horas%TYPE;
        v_flag_elab_contrato      tipo_contrato.flag_elab_contrato%TYPE;
        v_flag_aloc_usuario       tipo_contrato.flag_aloc_usuario%TYPE;
        v_tem_horas               tipo_contrato.flag_tem_horas%TYPE;
        v_tem_fee                 tipo_contrato.flag_tem_fee%TYPE;
        v_cad_verif               pessoa.flag_cad_verif%TYPE;
        v_fis_verif               pessoa.flag_fis_verif%TYPE;
        v_status_fis_verif        pessoa.status_fis_verif%TYPE;
        v_identif_objeto          historico.identif_objeto%TYPE;
        v_compl_histor            historico.complemento%TYPE;
        v_historico_id            historico.historico_id%TYPE;
        v_xml_atual               CLOB;
        v_num_dias_ver_precif     NUMBER(10);
        v_num_dias_pessoa_cad_ver NUMBER(10);
        v_num_dias_pessoa_fis_ver NUMBER(10);
        v_num_dias_ver_horas      NUMBER(10);
        v_num_dias_aloc_usu       NUMBER(10);
        v_num_dias_parc_contr     NUMBER(10);
        v_data_hoje               DATE;
        v_data_prazo              DATE;
        v_tipo_ctr_elab_desc      VARCHAR2(200);
  --
    BEGIN
        v_qt := 0;
        v_data_hoje := sysdate;
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
        IF nvl(p_contrato_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A especificação do contrato é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_cod_contrato_elab) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A especificação do código contrato_elab é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF flag_validar(p_flag_commit) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag commit inválido.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                tipo = 'tipo_contrato_elab'
            AND codigo = p_cod_contrato_elab;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse código de contrato_elab não existe ('
                          || p_cod_contrato_elab
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_tipo_ctr_elab_desc := util_pkg.desc_retornar('tipo_contrato_elab', p_cod_contrato_elab);
  --
        SELECT
            tipo_contrato_id,
            flag_ctr_fisico
        INTO
            v_tipo_contrato_id,
            v_flag_ctr_fisico
        FROM
            contrato
        WHERE
            contrato_id = p_contrato_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            flag_verifi_precif,
            flag_verifi_horas,
            flag_elab_contrato,
            flag_aloc_usuario,
            flag_tem_horas,
            flag_tem_fee
        INTO
            v_flag_verifi_precif,
            v_flag_verifi_horas,
            v_flag_elab_contrato,
            v_flag_aloc_usuario,
            v_tem_horas,
            v_tem_fee
        FROM
            tipo_contrato
        WHERE
            tipo_contrato_id = v_tipo_contrato_id;
  --
        IF p_cod_contrato_elab = 'PREC' OR (
            p_cod_contrato_elab = 'TODOS'
            AND v_flag_verifi_precif = 'S'
        ) THEN
            v_num_dias_ver_precif := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_VER_PRECIF') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_ver_precif, 'N');
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'PREC',
                p_usuario_sessao_id,
                'PEND',
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );

        END IF;
  --
        IF p_cod_contrato_elab = 'CLIE' OR p_cod_contrato_elab = 'TODOS' THEN
            v_num_dias_pessoa_cad_ver := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_PESSOA_CAD_VER') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_pessoa_cad_ver, 'N');
   --
            SELECT
                contratante_id
            INTO v_pessoa_id
            FROM
                contrato
            WHERE
                contrato_id = p_contrato_id;
   --
            SELECT
                flag_cad_verif
            INTO v_cad_verif
            FROM
                pessoa
            WHERE
                pessoa_id = v_pessoa_id;
   --
            IF v_cad_verif = 'N' THEN
                v_status := 'PEND';
                v_data_hoje := NULL;
            ELSE
                v_status := 'PRON';
                v_data_hoje := sysdate;
            END IF;
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'CLIE',
                p_usuario_sessao_id,
                v_status,
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );

        END IF;
  --
        IF p_cod_contrato_elab = 'FISC' OR p_cod_contrato_elab = 'TODOS' THEN
            v_data_hoje := sysdate;
            v_num_dias_pessoa_fis_ver := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_PESSOA_FISCAL_VER') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_pessoa_fis_ver, 'N');
   --
            SELECT
                contratante_id
            INTO v_pessoa_id
            FROM
                contrato
            WHERE
                contrato_id = p_contrato_id;
   --
            SELECT
                flag_fis_verif,
                status_fis_verif
            INTO
                v_fis_verif,
                v_status_fis_verif
            FROM
                pessoa
            WHERE
                pessoa_id = v_pessoa_id;
   --
            IF v_fis_verif = 'N' OR v_status_fis_verif = 'NOK' THEN
                v_status := 'PEND';
                v_data_hoje := NULL;
            ELSE
                v_status := 'PRON';
                v_data_hoje := sysdate;
            END IF;
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'FISC',
                p_usuario_sessao_id,
                v_status,
                v_data_prazo,
                v_data_hoje,
                NULL,
                NULL
            );

        END IF;
  --
        IF p_cod_contrato_elab = 'HORA' OR (
            p_cod_contrato_elab = 'TODOS'
            AND v_flag_verifi_horas = 'S'
        ) THEN
            v_data_hoje := sysdate;
            v_num_dias_ver_horas := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_VER_HORAS') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_ver_horas, 'N');
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'HORA',
                p_usuario_sessao_id,
                'PEND',
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );

        END IF;
  --
        IF p_cod_contrato_elab = 'FISI' OR (
            p_cod_contrato_elab = 'TODOS'
            AND ( v_flag_elab_contrato = 'S' OR v_flag_ctr_fisico = 'S' )
        ) THEN
            v_data_hoje := sysdate;
            v_num_dias_parc_contr := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_ELAB_CTR_FIS') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_parc_contr, 'N');
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'FISI',
                p_usuario_sessao_id,
                'PEND',
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );
   --
            contrato_fisico_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, p_contrato_id, NULL, 'N',
                                         p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
        IF p_cod_contrato_elab = 'ALOC' OR (
            p_cod_contrato_elab = 'TODOS'
            AND v_flag_aloc_usuario = 'S'
        ) THEN
            v_data_hoje := sysdate;
            v_num_dias_aloc_usu := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_ALOC_USU') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_aloc_usu, 'N');
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'ALOC',
                p_usuario_sessao_id,
                'PEND',
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );

        END IF;
  --
        IF p_cod_contrato_elab = 'PARC' OR (
            p_cod_contrato_elab = 'TODOS'
            AND v_tem_horas = 'S'
            AND v_tem_fee = 'S'
        ) THEN
            v_data_hoje := sysdate;
            v_num_dias_parc_contr := TO_NUMBER ( empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_PARC_CONTR') );
            v_data_prazo := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_hoje, v_num_dias_parc_contr, 'N');
   --
            SELECT
                seq_contrato_elab.NEXTVAL
            INTO v_contrato_elab_id
            FROM
                dual;
   --
            INSERT INTO contrato_elab (
                contrato_elab_id,
                contrato_id,
                cod_contrato_elab,
                usuario_id,
                status,
                data_prazo,
                data_execucao,
                motivo,
                data_motivo
            ) VALUES (
                v_contrato_elab_id,
                p_contrato_id,
                'PARC',
                p_usuario_sessao_id,
                'PEND',
                v_data_prazo,
                NULL,
                NULL,
                NULL
            );
   --
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
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := contrato_pkg.numero_formatar(p_contrato_id);
        v_compl_histor := 'Inclusão de CONTRATO ELAB: ' || v_tipo_ctr_elab_desc;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CONTRATO', 'ALTERAR', v_identif_objeto,
                        p_contrato_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
        p_erro_msg := 'Operação realizada com sucesso.';
  --
    EXCEPTION
        WHEN v_exception THEN
            ROLLBACK;
        WHEN OTHERS THEN
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END adicionar;
 --
 --
    PROCEDURE acao_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: José Mario Scardelatto  ProcessMind     DATA: 06/06/2022
  -- DESCRICAO: Executa transicao de status de contrato elab
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN contrato.empresa_id%TYPE,
        p_contrato_elab_id  IN contrato_elab.contrato_elab_id%TYPE,
        p_cod_acao          IN ct_transicao.cod_acao%TYPE,
        p_motivo            IN contrato_elab.motivo%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                 INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto     historico.identif_objeto%TYPE;
        v_compl_histor       historico.complemento%TYPE;
        v_historico_id       historico.historico_id%TYPE;
        v_contrato_id        contrato_elab.contrato_id%TYPE;
        v_xml_atual          CLOB;
        v_status_de          contrato_elab.status%TYPE;
        v_status_para        ct_transicao.status_para%TYPE;
        v_motivo             contrato_elab.motivo%TYPE;
        v_data_motivo        contrato_elab.data_motivo%TYPE;
        v_data_exec          contrato_elab.data_execucao%TYPE;
        v_cod_contrato_elab  contrato_elab.cod_contrato_elab%TYPE;
        v_tipo_ctr_elab_desc VARCHAR2(200);
        v_desc_transicao     VARCHAR2(200);
  --
    BEGIN
        v_qt := 0;
        v_data_exec := sysdate;
        v_data_motivo := sysdate;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            contrato_elab
        WHERE
            contrato_elab_id = p_contrato_elab_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse contrato elab não existe.';
            RAISE v_exception;
        END IF;
  --
        IF flag_validar(p_flag_commit) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag commit inválido.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            status,
            contrato_id,
            cod_contrato_elab
        INTO
            v_status_de,
            v_contrato_id,
            v_cod_contrato_elab
        FROM
            contrato_elab
        WHERE
            contrato_elab_id = p_contrato_elab_id;
  --
        v_tipo_ctr_elab_desc := util_pkg.desc_retornar('tipo_contrato_elab', v_cod_contrato_elab);
  --
        IF p_cod_acao = 'NAO_FAZER' THEN
   --
            IF TRIM(p_motivo) IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Para esse tipo de ação, o preenchimento do comentário é obrigatório.';
                RAISE v_exception;
            END IF;
        END IF;
  --
        SELECT
            MAX(status_para),
            MAX(descricao)
        INTO
            v_status_para,
            v_desc_transicao
        FROM
            ct_transicao
        WHERE
                cod_acao = p_cod_acao
            AND status_de = v_status_de
            AND cod_objeto = 'CONTRATO_ELAB';
  --
        IF v_status_para IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Transição inválida de CONTRATO ELAB ('
                          || v_status_de
                          || ' - '
                          || p_cod_acao
                          || ')';
            RAISE v_exception;
        END IF;
  --
        IF p_cod_acao = 'FAZER' THEN
   -- VERIFICAR CÁLCULO DE PRAZO
   --
            v_motivo := NULL;
            v_data_motivo := NULL;
   --
        ELSIF p_cod_acao = 'NAO_FAZER' THEN
   -- VERIFICAR CÁLCULO DE PRAZO
   --
            v_motivo := p_motivo;
        ELSIF p_cod_acao = 'TORNAR_PEND' THEN
   -- VERIFICAR CÁLCULO DE PRAZO
   --
            v_motivo := p_motivo;
        END IF;
  --
        UPDATE contrato_elab c
        SET
            c.status = v_status_para,
            c.usuario_id = p_usuario_sessao_id,
            c.data_execucao = v_data_exec,
            c.motivo = v_motivo,
            c.data_motivo = v_data_motivo
        WHERE
            contrato_elab_id = p_contrato_elab_id;
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
        v_identif_objeto := contrato_pkg.numero_formatar(v_contrato_id);
        v_compl_histor := 'Transição de CONTRATO ELAB: '
                          || v_tipo_ctr_elab_desc
                          || ' - '
                          || v_desc_transicao
                          || ' (de: '
                          || v_status_de
                          || ' para: '
                          || v_status_para
                          || ')';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CONTRATO', 'ALTERAR', v_identif_objeto,
                        v_contrato_id, v_compl_histor, v_motivo, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
        p_erro_msg := 'Operação realizada com sucesso.';
  --
    EXCEPTION
        WHEN v_exception THEN
            ROLLBACK;
        WHEN OTHERS THEN
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END acao_executar;
 --
--
END; -- CONTRATO_ELAB_PKG



/
