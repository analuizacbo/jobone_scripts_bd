--------------------------------------------------------
--  DDL for Package Body DOCUMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DOCUMENTO_PKG" IS
 --
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 07/12/2004
  -- DESCRICAO: Inclusão de documento de job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/01/2016  Novo parametro item_crono_id (abertura atraves do crono)
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN documento.job_id%TYPE,
        p_papel_resp_id     IN documento.papel_resp_id%TYPE,
        p_tipo_documento_id IN documento.tipo_documento_id%TYPE,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_tipo_fluxo        IN documento.tipo_fluxo%TYPE,
        p_vetor_papel_id    IN LONG,
        p_prioridade        IN task.prioridade%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_item_crono_id     IN item_crono.item_crono_id%TYPE,
        p_documento_id      OUT documento.documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt              INTEGER;
        v_exception EXCEPTION;
        v_documento_id    documento.documento_id%TYPE;
        v_identif_objeto  historico.identif_objeto%TYPE;
        v_compl_histor    historico.complemento%TYPE;
        v_historico_id    historico.historico_id%TYPE;
        v_numero_job      job.numero%TYPE;
        v_status_job      job.status%TYPE;
        v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
        v_flag_sistema    tipo_documento.flag_sistema%TYPE;
        v_nome_tipo_doc   tipo_documento.nome%TYPE;
        v_complemento     VARCHAR2(100);
        v_lbl_job         VARCHAR2(100);
        v_objeto_id       item_crono.objeto_id%TYPE;
        v_cod_objeto      item_crono.cod_objeto%TYPE;
        v_cronograma_id   item_crono.cronograma_id%TYPE;
        v_item_crono_id   item_crono.item_crono_id%TYPE;
        v_cod_acao        VARCHAR2(20);
        v_xml_atual       CLOB;
  --
    BEGIN
        v_qt := 0;
        p_documento_id := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job
        WHERE
                job_id = p_job_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_job
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        IF nvl(p_tipo_documento_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do tipo de documento é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            tipo_documento
        WHERE
                tipo_documento_id = p_tipo_documento_id
            AND flag_ativo = 'S'
            AND flag_arq_externo = 'N'
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Tipo de documento inválido.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            flag_sistema,
            nome
        INTO
            v_flag_sistema,
            v_nome_tipo_doc
        FROM
            tipo_documento
        WHERE
            tipo_documento_id = p_tipo_documento_id;
  --
        SELECT
            numero,
            status
        INTO
            v_numero_job,
            v_status_job
        FROM
            job
        WHERE
            job_id = p_job_id;
  --
        IF p_flag_commit = 'S' THEN
   -- verifica se o usuario tem privilegio
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', p_job_id, p_tipo_documento_id, p_empresa_id) <> 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF nvl(p_item_crono_id, 0) <> 0 THEN
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                item_crono ic,
                cronograma cr
            WHERE
                    ic.item_crono_id = p_item_crono_id
                AND ic.cronograma_id = cr.cronograma_id
                AND cr.job_id = p_job_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Esse item de cronograma não existe ou não pertence a esse '
                              || v_lbl_job
                              || '.';
                RAISE v_exception;
            END IF;
   --
            SELECT
                objeto_id,
                cod_objeto
            INTO
                v_objeto_id,
                v_cod_objeto
            FROM
                item_crono
            WHERE
                item_crono_id = p_item_crono_id;
   --
            IF v_objeto_id IS NOT NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Esse item de cronograma já está associado a algum tipo de objeto.';
                RAISE v_exception;
            END IF;
   --
            IF
                v_cod_objeto IS NOT NULL
                AND v_cod_objeto <> 'DOCUMENTO'
            THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Esse item de cronograma não pode ser usado para Documentos ('
                              || v_cod_objeto
                              || ').';
                RAISE v_exception;
            END IF;

        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_nome) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do nome do documento é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_nome) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O nome do documento não pode ter mais que 100 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 200 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição do documento não pode ter mais que 200 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF nvl(p_papel_resp_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do papel do responsável é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            papel
        WHERE
                papel_id = p_papel_resp_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse papel responsável não existe.';
            RAISE v_exception;
        END IF;
  --
  /*
    IF NVL(p_arquivo_id,0) = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O preenchimento do arquivo é obrigatório.';
       RAISE v_exception;
    END IF;
  */
  --
        IF length(p_comentario) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_tipo_fluxo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O tipo de solicitação deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            v_tipo_fluxo
        WHERE
            codigo = p_tipo_fluxo;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Tipo de solicitação inválido.';
            RAISE v_exception;
        END IF;
  --
        IF
            p_tipo_fluxo <> 'ND'
            AND rtrim(p_vetor_papel_id) IS NULL
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Para esse tipo de solicitação, pelo menos um papel deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
        IF
            p_tipo_fluxo = 'ND'
            AND rtrim(p_vetor_papel_id) IS NOT NULL
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Para esse tipo de solicitação, nenhum papel deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento
        WHERE
                job_id = p_job_id
            AND tipo_documento_id = p_tipo_documento_id
            AND upper(nome) = upper(p_nome);
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse nome de documento já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_documento.NEXTVAL
        INTO v_documento_id
        FROM
            dual;
  --
        INSERT INTO documento (
            documento_id,
            job_id,
            papel_resp_id,
            tipo_documento_id,
            usuario_id,
            nome,
            descricao,
            versao,
            data_versao,
            flag_atual,
            comentario,
            tipo_fluxo,
            status
        ) VALUES (
            v_documento_id,
            p_job_id,
            p_papel_resp_id,
            p_tipo_documento_id,
            p_usuario_sessao_id,
            p_nome,
            p_descricao,
            1,
            sysdate,
            'S',
            p_comentario,
            p_tipo_fluxo,
            decode(p_tipo_fluxo, 'ND', 'OK', 'PEND')
        );
  --
  ------------------------------------------------------------
  -- criacao de tasks
  ------------------------------------------------------------
  -- acao padrao para o evento de historico/notificacao
        v_cod_acao := 'INCLUIR';
  --
        IF p_tipo_fluxo = 'AP' THEN
            v_complemento := 'Aprovação';
            v_cod_acao := 'ENVIAR_APROV';
        ELSIF p_tipo_fluxo = 'CO' THEN
            v_complemento := 'Comentário';
        ELSIF p_tipo_fluxo = 'CI' THEN
            v_complemento := 'Ciência';
        ELSE
            v_complemento := NULL;
        END IF;
  --
        IF rtrim(p_vetor_papel_id) IS NOT NULL THEN
   -- gera task de analise de documento
            documento_pkg.task_gerar(p_usuario_sessao_id, p_empresa_id, 'N', v_documento_id, 'DOC_ANALISE_MSG',
                                    p_prioridade, p_vetor_papel_id, v_complemento, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  ------------------------------------------------------------
  -- criacao do arquivo
  ------------------------------------------------------------
        IF nvl(p_arquivo_id, 0) > 0 THEN
            SELECT
                MAX(tipo_arquivo_id)
            INTO v_tipo_arquivo_id
            FROM
                tipo_arquivo
            WHERE
                    empresa_id = p_empresa_id
                AND codigo = 'DOCUMENTO';
   --
            arquivo_pkg.adicionar(p_usuario_sessao_id, p_arquivo_id, p_volume_id, v_documento_id, v_tipo_arquivo_id,
                                 p_nome_original, p_nome_fisico, NULL, p_mime_type, p_tamanho,
                                 p_palavras_chave, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
        IF nvl(p_item_crono_id, 0) <> 0 THEN
   -- documento criado via cronograma
            UPDATE item_crono
            SET
                objeto_id = v_documento_id,
                cod_objeto = 'DOCUMENTO'
            WHERE
                item_crono_id = p_item_crono_id;

        ELSE
   -- documento criado por fora do cronograma
            v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
   --
            IF nvl(v_cronograma_id, 0) = 0 THEN
    -- cria o primeiro cronograma com as atividades obrigatorias
                cronograma_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', p_job_id, v_cronograma_id,
                                        p_erro_cod, p_erro_msg);

                IF p_erro_cod <> '00000' THEN
                    RAISE v_exception;
                END IF;
            END IF;
   --
            IF v_flag_sistema = 'N' THEN
    -- cria a atividade de documento
                cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id, p_empresa_id, v_cronograma_id, 'DOCUMENTO', 'IME',
                                                    v_item_crono_id, p_erro_cod, p_erro_msg);

                IF p_erro_cod <> '00000' THEN
                    RAISE v_exception;
                END IF;
    --
    -- vincula a atividade de documento ao documento criado
                UPDATE item_crono
                SET
                    objeto_id = v_documento_id,
                    nome = substr('Documento ' || TRIM(p_nome),
                                  1,
                                  100)
                WHERE
                    item_crono_id = v_item_crono_id;

            END IF;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(v_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := v_documento_id;
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || p_nome;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', v_cod_acao, v_identif_objeto,
                        v_documento_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        IF p_flag_commit = 'S' THEN
            COMMIT;
        END IF;
        p_documento_id := v_documento_id;
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
    PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 29/12/2004
  -- DESCRICAO: Atualizacao de documento de job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_nome              documento.nome%TYPE;
        v_descricao         documento.descricao%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_tipo_fluxo        documento.tipo_fluxo%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_job_id            job.job_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_tipo_objeto_id    task.tipo_objeto_id%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_xml_antes         CLOB;
        v_xml_atual         CLOB;
  --
        CURSOR c_task IS
        SELECT
            task_id
        FROM
            task
        WHERE
                objeto_id = p_documento_id
            AND tipo_objeto_id = v_tipo_objeto_id
            AND flag_fechado = 'S';
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento dc,
            job       jo
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            jo.job_id,
            jo.numero,
            jo.status,
            dc.tipo_documento_id,
            dc.nome,
            dc.flag_atual,
            dc.tipo_fluxo,
            td.nome
        INTO
            v_job_id,
            v_numero_job,
            v_status_job,
            v_tipo_documento_id,
            v_nome,
            v_flag_atual,
            v_tipo_fluxo,
            v_nome_tipo_doc
        FROM
            documento      dc,
            job            jo,
            tipo_documento td
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND dc.tipo_documento_id = td.tipo_documento_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_flag_atual = 'N' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Apenas a versão mais recente do documento (versão atual) ' || 'pode ser alterada.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_nome) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do nome do documento é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_nome) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O nome do documento não pode ter mais que 100 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 200 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição do documento não pode ter mais que 200 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_comentario) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  -- verifica se mudou o nome do documento
        IF v_nome <> p_nome THEN
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                documento
            WHERE
                    job_id = v_job_id
                AND tipo_documento_id = v_tipo_documento_id
                AND nome = v_nome;
   --
            IF v_qt > 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'O nome desse documento não pode ser alterado ' || 'pois já existe mais de uma versão.';
                RAISE v_exception;
            END IF;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE documento
        SET
            nome = p_nome,
            descricao = p_descricao,
            comentario = p_comentario
        WHERE
            documento_id = p_documento_id;
  --
  ------------------------------------------------------------
  -- reabertura do fluxo / tasks
  ------------------------------------------------------------
        IF v_tipo_fluxo <> 'ND' THEN
   -- se o doc fizer parte de um fluxo definido, volta o fluxo
   -- para pendente.
            UPDATE documento
            SET
                status = 'PEND',
                consolidacao = NULL
            WHERE
                documento_id = p_documento_id;
   --
            SELECT
                MAX(tipo_objeto_id)
            INTO v_tipo_objeto_id
            FROM
                tipo_objeto
            WHERE
                codigo = 'DOCUMENTO';
   --
            IF v_tipo_objeto_id IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Erro na recuperação do tipo de objeto.';
                RAISE v_exception;
            END IF;
   --
   -- reabre as tasks fechadas
            FOR r_task IN c_task LOOP
                UPDATE task
                SET
                    flag_fechado = 'N'
                WHERE
                    task_id = r_task.task_id;
    --
    -- gera historico
                task_pkg.historico_gerar(p_usuario_sessao_id, p_empresa_id, r_task.task_id, 'REABERTURA', p_erro_cod,
                                        p_erro_msg);
    --
                IF p_erro_cod <> '00000' THEN
                    RAISE v_exception;
                END IF;
            END LOOP;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || p_nome;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', 'ALTERAR', v_identif_objeto,
                        p_documento_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END atualizar;
 --
 --
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 27/12/2017
  -- DESCRICAO: Exclusao de documento de job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/10/2018  Tratamento de cronograma
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_nome              documento.nome%TYPE;
        v_descricao         documento.descricao%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_tipo_fluxo        documento.tipo_fluxo%TYPE;
        v_versao            documento.versao%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_job_id            job.job_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_tipo_objeto_id    task.tipo_objeto_id%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_xml_antes         CLOB;
        v_xml_atual         CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento dc,
            job       jo
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            jo.job_id,
            jo.numero,
            jo.status,
            dc.tipo_documento_id,
            dc.nome,
            dc.flag_atual,
            dc.tipo_fluxo,
            td.nome
        INTO
            v_job_id,
            v_numero_job,
            v_status_job,
            v_tipo_documento_id,
            v_nome,
            v_flag_atual,
            v_tipo_fluxo,
            v_nome_tipo_doc
        FROM
            documento      dc,
            job            jo,
            tipo_documento td
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND dc.tipo_documento_id = td.tipo_documento_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_flag_atual = 'N' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Apenas a versão mais recente do documento (versão atual) ' || 'pode ser excluída.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            arquivo_documento
        WHERE
            documento_id = p_documento_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Apenas documentos sem arquivos podem ser excluídos.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM task_hist th
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    task ta
                WHERE
                        ta.task_id = th.task_id
                    AND ta.objeto_id = p_documento_id
                    AND ta.tipo_objeto_id = (
                        SELECT
                            tipo_objeto_id
                        FROM
                            tipo_objeto
                        WHERE
                            codigo = 'DOCUMENTO'
                    )
            );

        DELETE FROM task
        WHERE
                objeto_id = p_documento_id
            AND tipo_objeto_id = (
                SELECT
                    tipo_objeto_id
                FROM
                    tipo_objeto
                WHERE
                    codigo = 'DOCUMENTO'
            );

        DELETE FROM documento
        WHERE
            documento_id = p_documento_id;
  --
        SELECT
            MAX(versao)
        INTO v_versao
        FROM
            documento
        WHERE
                job_id = v_job_id
            AND tipo_documento_id = v_tipo_documento_id
            AND nome = v_nome;
  --
        IF v_versao IS NOT NULL THEN
            UPDATE documento
            SET
                flag_atual = 'S'
            WHERE
                    job_id = v_job_id
                AND tipo_documento_id = v_tipo_documento_id
                AND nome = v_nome
                AND versao = v_versao;

        END IF;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
        UPDATE item_crono ic
        SET
            objeto_id = NULL
        WHERE
                cod_objeto = 'DOCUMENTO'
            AND objeto_id = p_documento_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || v_nome;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', 'EXCLUIR', v_identif_objeto,
                        p_documento_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END excluir;
 --
 --
    PROCEDURE versao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 29/12/2004
  -- DESCRICAO: Inclusão de nova versao de documento de job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/01/2016  Tratamento de cronograma.
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id    IN NUMBER,
        p_empresa_id           IN empresa.empresa_id%TYPE,
        p_flag_commit          IN VARCHAR2,
        p_job_id               IN documento.job_id%TYPE,
        p_papel_resp_id        IN documento.papel_resp_id%TYPE,
        p_documento_origem_id  IN documento.documento_id%TYPE,
        p_comentario           IN VARCHAR2,
        p_tipo_fluxo           IN documento.tipo_fluxo%TYPE,
        p_vetor_papel_id       IN LONG,
        p_prioridade           IN task.prioridade%TYPE,
        p_flag_manter_arquivos IN VARCHAR2,
        p_arquivo_id           IN arquivo.arquivo_id%TYPE,
        p_volume_id            IN arquivo.volume_id%TYPE,
        p_nome_original        IN arquivo.nome_original%TYPE,
        p_nome_fisico          IN arquivo.nome_fisico%TYPE,
        p_mime_type            IN arquivo.mime_type%TYPE,
        p_tamanho              IN arquivo.tamanho%TYPE,
        p_palavras_chave       IN VARCHAR2,
        p_documento_id         OUT documento.documento_id%TYPE,
        p_erro_cod             OUT VARCHAR2,
        p_erro_msg             OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_documento_id      documento.documento_id%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_nome              documento.nome%TYPE;
        v_descricao         documento.descricao%TYPE;
        v_versao            documento.versao%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_flag_sistema      tipo_documento.flag_sistema%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_tipo_arquivo_id   tipo_arquivo.tipo_arquivo_id%TYPE;
        v_complemento       VARCHAR2(100);
        v_lbl_job           VARCHAR2(100);
        v_cronograma_id     item_crono.cronograma_id%TYPE;
        v_item_crono_id     item_crono.item_crono_id%TYPE;
        v_cod_acao          VARCHAR2(20);
        v_xml_atual         CLOB;
  --
    BEGIN
        v_qt := 0;
        p_documento_id := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
        IF flag_validar(p_flag_manter_arquivos) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag manter arquivos inválido.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job
        WHERE
                job_id = p_job_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_job
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            numero,
            status
        INTO
            v_numero_job,
            v_status_job
        FROM
            job
        WHERE
            job_id = p_job_id;
  --
        IF v_numero_job IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_job
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
  -- seleciona dados do documento de origem
        SELECT
            MAX(tipo_documento_id),
            MAX(nome),
            MAX(descricao)
        INTO
            v_tipo_documento_id,
            v_nome,
            v_descricao
        FROM
            documento
        WHERE
                job_id = p_job_id
            AND documento_id = p_documento_origem_id;
  --
        IF v_tipo_documento_id IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O documento de origem não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            flag_sistema,
            nome
        INTO
            v_flag_sistema,
            v_nome_tipo_doc
        FROM
            tipo_documento
        WHERE
            tipo_documento_id = v_tipo_documento_id;
  --
        IF p_flag_commit = 'S' THEN
   -- verifica se o usuario tem privilegio
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', p_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF nvl(p_documento_origem_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do documento de origem é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF nvl(p_papel_resp_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do papel do responsável é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            papel
        WHERE
                papel_id = p_papel_resp_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse papel responsável não existe.';
            RAISE v_exception;
        END IF;
  --
        IF
            p_flag_manter_arquivos = 'S'
            AND nvl(p_arquivo_id, 0) > 0
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Para utilizar os mesmos arquivos da versão anterior, ' || 'o arquivo não deve ser preenchido.';
            RAISE v_exception;
        END IF;
  --
  /*
    IF p_flag_manter_arquivos = 'N' AND NVL(p_arquivo_id,0) = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Nenhum arquivo foi associado ao documento.';
       RAISE v_exception;
    END IF;
  */
  --
        IF length(p_comentario) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_tipo_fluxo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O tipo de solicitação deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            v_tipo_fluxo
        WHERE
            codigo = p_tipo_fluxo;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Tipo de solicitação inválido.';
            RAISE v_exception;
        END IF;
  --
        IF
            p_tipo_fluxo <> 'ND'
            AND rtrim(p_vetor_papel_id) IS NULL
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Para esse tipo de solicitação, pelo menos um papel deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
        IF
            p_tipo_fluxo = 'ND'
            AND rtrim(p_vetor_papel_id) IS NOT NULL
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Para esse tipo de solicitação, nenhum papel deve ser especificado.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  -- verifica se existem versoes desse documento nao consolidadas
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento
        WHERE
                job_id = p_job_id
            AND tipo_documento_id = v_tipo_documento_id
            AND nome = v_nome
            AND status = 'PEND';
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem versões desse documento que ainda não foram consolidadas.';
            RAISE v_exception;
        END IF;
  --
  -- seleciona a versao atual
        SELECT
            MAX(versao)
        INTO v_versao
        FROM
            documento
        WHERE
                job_id = p_job_id
            AND tipo_documento_id = v_tipo_documento_id
            AND nome = v_nome
            AND flag_atual = 'S';
  --
        IF v_versao IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Nao foi encontrada a versão atual desse documento.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE documento
        SET
            flag_atual = 'N'
        WHERE
                job_id = p_job_id
            AND tipo_documento_id = v_tipo_documento_id
            AND nome = v_nome
            AND versao = v_versao;
  --
        v_versao := v_versao + 1;
  --
        SELECT
            seq_documento.NEXTVAL
        INTO v_documento_id
        FROM
            dual;
  --
        INSERT INTO documento (
            documento_id,
            job_id,
            papel_resp_id,
            tipo_documento_id,
            usuario_id,
            nome,
            descricao,
            versao,
            data_versao,
            flag_atual,
            comentario,
            tipo_fluxo,
            status
        ) VALUES (
            v_documento_id,
            p_job_id,
            p_papel_resp_id,
            v_tipo_documento_id,
            p_usuario_sessao_id,
            v_nome,
            v_descricao,
            v_versao,
            sysdate,
            'S',
            p_comentario,
            p_tipo_fluxo,
            decode(p_tipo_fluxo, 'ND', 'OK', 'PEND')
        );
  --
  ------------------------------------------------------------
  -- criacao de tasks
  ------------------------------------------------------------
  -- acao padrao para o evento de historico/notificacao
        v_cod_acao := 'INCLUIR';
  --
        IF p_tipo_fluxo = 'AP' THEN
            v_complemento := 'Aprovação';
            v_cod_acao := 'ENVIAR_APROV';
        ELSIF p_tipo_fluxo = 'CO' THEN
            v_complemento := 'Comentário';
        ELSIF p_tipo_fluxo = 'CI' THEN
            v_complemento := 'Ciência';
        ELSE
            v_complemento := NULL;
        END IF;
  --
        IF rtrim(p_vetor_papel_id) IS NOT NULL THEN
   -- gera task de analise de documento
            documento_pkg.task_gerar(p_usuario_sessao_id, p_empresa_id, 'N', v_documento_id, 'DOC_ANALISE_MSG',
                                    p_prioridade, p_vetor_papel_id, v_complemento, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  ------------------------------------------------------------
  -- criacao do arquivo
  ------------------------------------------------------------
        IF nvl(p_arquivo_id, 0) > 0 THEN
            SELECT
                MAX(tipo_arquivo_id)
            INTO v_tipo_arquivo_id
            FROM
                tipo_arquivo
            WHERE
                    empresa_id = p_empresa_id
                AND codigo = 'DOCUMENTO';
   --
            arquivo_pkg.adicionar(p_usuario_sessao_id, p_arquivo_id, p_volume_id, v_documento_id, v_tipo_arquivo_id,
                                 p_nome_original, p_nome_fisico, NULL, p_mime_type, p_tamanho,
                                 p_palavras_chave, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        ELSIF p_flag_manter_arquivos = 'S' THEN
   -- pega os arquivos da versao anterior
            INSERT INTO arquivo_documento (
                arquivo_id,
                documento_id
            )
                SELECT
                    arquivo_id,
                    v_documento_id
                FROM
                    arquivo_documento
                WHERE
                    documento_id = p_documento_origem_id;

        END IF;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
        v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
  --
        IF nvl(v_cronograma_id, 0) = 0 THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
            cronograma_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', p_job_id, v_cronograma_id,
                                    p_erro_cod, p_erro_msg);

            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  -- verifica se documento origem ja esta no cronograma atual
        SELECT
            MAX(ic.item_crono_id)
        INTO v_item_crono_id
        FROM
            item_crono ic,
            cronograma cr
        WHERE
                ic.cod_objeto = 'DOCUMENTO'
            AND ic.objeto_id = p_documento_origem_id
            AND ic.cronograma_id = cr.cronograma_id
            AND cr.cronograma_id = v_cronograma_id;
  --
        IF nvl(v_item_crono_id, 0) <> 0 THEN
   -- documento origem ja esta no cronograma. Atualiza para o novo.
            UPDATE item_crono
            SET
                objeto_id = v_documento_id,
                cod_objeto = 'DOCUMENTO'
            WHERE
                item_crono_id = v_item_crono_id;

        ELSIF v_flag_sistema = 'N' THEN
   -- cria a atividade de documento
            cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id, p_empresa_id, v_cronograma_id, 'DOCUMENTO', 'IME',
                                                v_item_crono_id, p_erro_cod, p_erro_msg);

            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
   --
   -- vincula a atividade de documento ao documento criado
            UPDATE item_crono
            SET
                objeto_id = v_documento_id,
                nome = substr('Documento ' || TRIM(v_nome),
                              1,
                              100)
            WHERE
                item_crono_id = v_item_crono_id;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(v_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || v_nome
                          || ' (Nova versão)';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', v_cod_acao, v_identif_objeto,
                        v_documento_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        IF p_flag_commit = 'S' THEN
            COMMIT;
        END IF;
        p_documento_id := v_documento_id;
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
    END; -- versao_adicionar
 --
 --
    PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/10/2007
  -- DESCRICAO: Adicionar arquivo no documento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/03/2011  Retirada do parametro empresa_id.
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_documento_id      IN arquivo_documento.documento_id%TYPE,
        p_descricao         IN arquivo.descricao%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_job_id            job.job_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_nome              documento.nome%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_tipo_fluxo        documento.tipo_fluxo%TYPE;
        v_tipo_objeto_id    task.tipo_objeto_id%TYPE;
        v_tam_max_arq       tipo_documento.tam_max_arq%TYPE;
        v_qtd_max_arq       tipo_documento.qtd_max_arq%TYPE;
        v_extensoes         tipo_documento.extensoes%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_tipo_arquivo_id   tipo_arquivo.tipo_arquivo_id%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_extensao          VARCHAR2(200);
        v_qtd_arq           NUMBER(10);
        v_xml_antes         CLOB;
        v_xml_atual         CLOB;
  --
        CURSOR c_task IS
        SELECT
            task_id
        FROM
            task
        WHERE
                objeto_id = p_documento_id
            AND tipo_objeto_id = v_tipo_objeto_id
            AND flag_fechado = 'S';
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento dc
        WHERE
            dc.documento_id = p_documento_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            jo.job_id,
            jo.numero,
            jo.status,
            dc.tipo_documento_id,
            dc.nome,
            dc.flag_atual,
            dc.tipo_fluxo,
            ti.tam_max_arq,
            ti.qtd_max_arq,
            ti.extensoes,
            ti.nome
        INTO
            v_job_id,
            v_numero_job,
            v_status_job,
            v_tipo_documento_id,
            v_nome,
            v_flag_atual,
            v_tipo_fluxo,
            v_tam_max_arq,
            v_qtd_max_arq,
            v_extensoes,
            v_nome_tipo_doc
        FROM
            documento      dc,
            job            jo,
            tipo_documento ti
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id
            AND dc.tipo_documento_id = ti.tipo_documento_id;
  --
        SELECT
            COUNT(*)
        INTO v_qtd_arq
        FROM
            arquivo_documento
        WHERE
            documento_id = p_documento_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_flag_atual = 'N' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Apenas a versão mais recente do documento (versão atual) ' || 'pode ser alterada.';
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
        IF
            v_tam_max_arq IS NOT NULL
            AND p_tamanho > v_tam_max_arq
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O tamanho do arquivo não pode ser maior que '
                          || to_char(v_tam_max_arq)
                          || ' bytes.';
            RAISE v_exception;
        END IF;
  --
        IF v_extensoes IS NOT NULL THEN
            v_extensao := substr(p_nome_fisico, instr(p_nome_fisico, '.') + 1);
   --
            IF instr(upper(','
                           || v_extensoes
                           || ','), upper(','
                                          || v_extensao
                                          || ',')) = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Essa extensão do arquivo ('
                              || upper(v_extensao)
                              || ') não é uma das extensões válidas ('
                              || upper(v_extensoes)
                              || ').';

                RAISE v_exception;
            END IF;

        END IF;
  --
        IF
            v_qtd_max_arq IS NOT NULL
            AND v_qtd_arq + 1 > v_qtd_max_arq
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A quantidade de arquivos anexados não pode ser maior que '
                          || to_char(v_qtd_max_arq)
                          || '.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            MAX(tipo_arquivo_id)
        INTO v_tipo_arquivo_id
        FROM
            tipo_arquivo
        WHERE
                empresa_id = p_empresa_id
            AND codigo = 'DOCUMENTO';
  --
        arquivo_pkg.adicionar(p_usuario_sessao_id, p_arquivo_id, p_volume_id, p_documento_id, v_tipo_arquivo_id,
                             p_nome_original, p_nome_fisico, p_descricao, p_mime_type, p_tamanho,
                             p_palavras_chave, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- reabertura do fluxo / tasks
  ------------------------------------------------------------
        IF v_tipo_fluxo <> 'ND' THEN
   -- se o doc fizer parte de um fluxo definido, volta o fluxo
   -- para pendente.
            UPDATE documento
            SET
                status = 'PEND',
                consolidacao = NULL
            WHERE
                documento_id = p_documento_id;
   --
            SELECT
                MAX(tipo_objeto_id)
            INTO v_tipo_objeto_id
            FROM
                tipo_objeto
            WHERE
                codigo = 'DOCUMENTO';
   --
            IF v_tipo_objeto_id IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Erro na recuperação do tipo de objeto.';
                RAISE v_exception;
            END IF;
   --
   -- reabre as tasks fechadas
            FOR r_task IN c_task LOOP
                UPDATE task
                SET
                    flag_fechado = 'N'
                WHERE
                    task_id = r_task.task_id;
    --
    -- gera historico
                task_pkg.historico_gerar(p_usuario_sessao_id, p_empresa_id, r_task.task_id, 'REABERTURA', p_erro_cod,
                                        p_erro_msg);
    --
                IF p_erro_cod <> '00000' THEN
                    RAISE v_exception;
                END IF;
            END LOOP;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || v_nome
                          || ' (Novo zarquivo: '
                          || p_nome_fisico
                          || ')';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', 'ALTERAR', v_identif_objeto,
                        p_documento_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END; -- arquivo_adicionar
 --
 --
    PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/10/2007
  -- DESCRICAO: Excluir arquivo de DOCUMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/06/2008  Tratamento de arquivos associados a multiplos documentos.
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_flag_remover      OUT VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_job_id            job.job_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_nome              documento.nome%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_tipo_fluxo        documento.tipo_fluxo%TYPE;
        v_nome_fisico       arquivo.nome_fisico%TYPE;
        v_tipo_objeto_id    task.tipo_objeto_id%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_xml_antes         CLOB;
        v_xml_atual         CLOB;
  --
        CURSOR c_task IS
        SELECT
            task_id
        FROM
            task
        WHERE
                objeto_id = p_documento_id
            AND tipo_objeto_id = v_tipo_objeto_id
            AND flag_fechado = 'S';
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  -- inicializa variavel de output que indica se o arquivo
  -- deve ser realmente removido do file system.
        p_flag_remover := 'S';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento         dc,
            arquivo_documento ar,
            job               jo
        WHERE
                ar.arquivo_id = p_arquivo_id
            AND ar.documento_id = dc.documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse arquivo não existe ou não está associado ao documento.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            ar.nome_fisico
        INTO v_nome_fisico
        FROM
            arquivo_documento ad,
            arquivo           ar
        WHERE
                ad.arquivo_id = p_arquivo_id
            AND ad.documento_id = p_documento_id
            AND ad.arquivo_id = ar.arquivo_id;
  --
        SELECT
            jo.job_id,
            jo.numero,
            jo.status,
            dc.tipo_documento_id,
            dc.nome,
            dc.flag_atual,
            dc.tipo_fluxo,
            td.nome
        INTO
            v_job_id,
            v_numero_job,
            v_status_job,
            v_tipo_documento_id,
            v_nome,
            v_flag_atual,
            v_tipo_fluxo,
            v_nome_tipo_doc
        FROM
            documento      dc,
            job            jo,
            tipo_documento td
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND dc.tipo_documento_id = td.tipo_documento_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_flag_atual = 'N' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Apenas a versão mais recente do documento (versão atual) ' || 'pode ser alterada.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se o arquivo esta associado a outros documentos
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            arquivo_documento
        WHERE
                arquivo_id = p_arquivo_id
            AND documento_id <> p_documento_id;
  --
        IF v_qt = 0 THEN
   -- nao esta. Pode excluir o arquivo.
            arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        ELSE
   -- esta associado a outros. Exclui apenas o relacionamento.
            DELETE FROM arquivo_documento
            WHERE
                    arquivo_id = p_arquivo_id
                AND documento_id = p_documento_id;
   --
   -- nao se exclui o arquivo fisicamente
            p_flag_remover := 'N';
        END IF;
  --
  ------------------------------------------------------------
  -- reabertura do fluxo / tasks
  ------------------------------------------------------------
        IF v_tipo_fluxo <> 'ND' THEN
   -- se o doc fizer parte de um fluxo definido, volta o fluxo
   -- para pendente.
            UPDATE documento
            SET
                status = 'PEND',
                consolidacao = NULL
            WHERE
                documento_id = p_documento_id;
   --
            SELECT
                MAX(tipo_objeto_id)
            INTO v_tipo_objeto_id
            FROM
                tipo_objeto
            WHERE
                codigo = 'DOCUMENTO';
   --
            IF v_tipo_objeto_id IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Erro na recuperação do tipo de objeto.';
                RAISE v_exception;
            END IF;
   --
   -- reabre as tasks fechadas
            FOR r_task IN c_task LOOP
                UPDATE task
                SET
                    flag_fechado = 'N'
                WHERE
                    task_id = r_task.task_id;
    --
    -- gera historico
                task_pkg.historico_gerar(p_usuario_sessao_id, p_empresa_id, r_task.task_id, 'REABERTURA', p_erro_cod,
                                        p_erro_msg);
    --
                IF p_erro_cod <> '00000' THEN
                    RAISE v_exception;
                END IF;
            END LOOP;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || v_nome
                          || ' (Exclusão de arquivo: '
                          || v_nome_fisico
                          || ')';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', 'ALTERAR', v_identif_objeto,
                        p_documento_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END; -- arquivo_excluir
 --
 --
    PROCEDURE consolidar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 29/12/2004
  -- DESCRICAO: consolidacao de documento de job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/09/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_flag_reprovado    IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_job_id            job.job_id%TYPE;
        v_status_doc        documento.status%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_flag_atual        documento.flag_atual%TYPE;
        v_nome              documento.nome%TYPE;
        v_tipo_objeto_id    tipo_objeto.tipo_objeto_id%TYPE;
        v_nome_tipo_doc     tipo_documento.nome%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_cod_acao          VARCHAR2(20);
        v_xml_antes         CLOB;
        v_xml_atual         CLOB;
  --
        CURSOR c_task IS
        SELECT
            task_id
        FROM
            task
        WHERE
                objeto_id = p_documento_id
            AND tipo_objeto_id = v_tipo_objeto_id
            AND flag_fechado = 'N';
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento dc,
            job       jo
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            d.status,
            d.tipo_documento_id,
            d.nome,
            t.nome
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_status_doc,
            v_tipo_documento_id,
            v_nome,
            v_nome_tipo_doc
        FROM
            job            j,
            documento      d,
            tipo_documento t
        WHERE
                d.documento_id = p_documento_id
            AND d.job_id = j.job_id
            AND d.tipo_documento_id = t.tipo_documento_id;
  --
        IF v_numero_job IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_status_job NOT IN ( 'PREP', 'ANDA' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            MAX(tipo_objeto_id)
        INTO v_tipo_objeto_id
        FROM
            tipo_objeto
        WHERE
            codigo = 'DOCUMENTO';
  --
        IF v_tipo_objeto_id IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Erro na recuperação do tipo de objeto.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF v_status_doc <> 'PEND' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento já foi consolidado.';
            RAISE v_exception;
        END IF;
  --
        IF flag_validar(p_flag_reprovado) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag reprovado inválido.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_comentario) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF p_flag_reprovado = 'S' THEN
            v_status_doc := 'NOK';
            v_cod_acao := 'REPROVAR';
        ELSE
            v_status_doc := 'OK';
            v_cod_acao := 'APROVAR';
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE documento
        SET
            status = v_status_doc,
            consolidacao = p_comentario
        WHERE
            documento_id = p_documento_id;
  --
        FOR r_task IN c_task LOOP
            task_pkg.fechar(p_usuario_sessao_id, p_empresa_id, 'N', -- flag_commit
             r_task.task_id, 'SIS', -- via sistema
                           NULL, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        documento_pkg.xml_gerar(p_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_documento_id);
        v_compl_histor := v_nome_tipo_doc
                          || ' - '
                          || v_nome;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', v_cod_acao, v_identif_objeto,
                        p_documento_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END; -- consolidar
 --
 --
    PROCEDURE task_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/08/2006
  -- DESCRICAO: Gera tasks relacionadas a um determinado documento do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_documento_id      IN documento.documento_id%TYPE,
        p_tipo_task         IN VARCHAR2,
        p_prioridade        IN task.prioridade%TYPE,
        p_vetor_papel_id    IN LONG,
        p_tipo_fluxo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_numero_job        job.numero%TYPE;
        v_status_job        job.status%TYPE;
        v_job_id            job.job_id%TYPE;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_papel_id          papel.papel_id%TYPE;
        v_delimitador       CHAR(1);
        v_vetor_papel_id    LONG;
        v_task_id           task.task_id%TYPE;
        v_tipo_objeto_id    task.tipo_objeto_id%TYPE;
        v_usuario           pessoa.apelido%TYPE;
        v_desc_curta        task.desc_curta%TYPE;
        v_desc_detalhada    task.desc_detalhada%TYPE;
        v_nome_doc          documento.nome%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_lbl_job           VARCHAR2(100);
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento dc,
            job       jo
        WHERE
                dc.documento_id = p_documento_id
            AND dc.job_id = jo.job_id
            AND jo.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse documento não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.job_id,
            j.status,
            d.nome,
            d.tipo_documento_id
        INTO
            v_numero_job,
            v_job_id,
            v_status_job,
            v_nome_doc,
            v_tipo_documento_id
        FROM
            job       j,
            documento d
        WHERE
                d.documento_id = p_documento_id
            AND d.job_id = j.job_id;
  --
        IF p_flag_commit = 'S' THEN
   -- verifica se o usuario tem privilegio
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DOCUMENTO_C', v_job_id, v_tipo_documento_id, p_empresa_id) <> 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  --
        IF v_status_job NOT IN ( 'ANDA', 'PREP' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            MAX(tipo_objeto_id)
        INTO v_tipo_objeto_id
        FROM
            tipo_objeto
        WHERE
            codigo = 'DOCUMENTO';
  --
        IF v_tipo_objeto_id IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Não existe tipo de objeto criado para documento.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            MAX(apelido)
        INTO v_usuario
        FROM
            pessoa
        WHERE
            usuario_id = p_usuario_sessao_id;
  --
        IF p_tipo_task NOT IN ( 'DOC_ANALISE_MSG' ) OR rtrim(p_tipo_task) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Tipo de task inválido.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_vetor_papel_id) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'É necessário indicar pelo menos um papel como responsável pela task.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        IF p_tipo_task = 'DOC_ANALISE_MSG' THEN
            v_desc_curta := p_tipo_fluxo || ' de Documento';
            v_desc_detalhada := rtrim(v_usuario
                                      || ' solicitou que analise o documento '
                                      || v_nome_doc
                                      || '('
                                      || p_tipo_fluxo
                                      || ')');

        END IF;
  --
        v_delimitador := ',';
        v_vetor_papel_id := p_vetor_papel_id;
  --
        WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0 LOOP
            v_papel_id := TO_NUMBER ( prox_valor_retornar(v_vetor_papel_id, v_delimitador) );
   --
            task_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', -- flag_commit
             v_job_id, 0, -- milestone_id
                              v_papel_id, v_desc_curta, v_desc_detalhada, p_prioridade, p_tipo_task,
                              v_task_id, -- output
                               p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
   --
   -- vincula o documento a essa task
            UPDATE task
            SET
                objeto_id = p_documento_id,
                tipo_objeto_id = v_tipo_objeto_id
            WHERE
                task_id = v_task_id;

        END LOOP;
  --
  /*
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
    v_identif_objeto := TO_CHAR(p_documento_id);
    v_compl_histor := 'Geração de tasks (documento)';
    --
    evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DOCUMENTO', 'ALTERAR',
                     v_identif_objeto, p_documento_id, v_compl_histor, NULL,
                     'N', NULL, NULL,
                     v_historico_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
    END IF;
  */
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
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END; -- task_gerar
 --
 --
    FUNCTION status_retornar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/12/2004
  -- DESCRICAO: retorna texto com a descricao do status do documento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN VARCHAR2 AS

        v_status     VARCHAR2(100);
        v_qt         INTEGER;
        v_status_cod documento.status%TYPE;
        v_tipo_fluxo documento.tipo_fluxo%TYPE;
        v_qtd_aberto NUMBER(5);
  --
    BEGIN
        v_status := NULL;
  --
        SELECT
            tipo_fluxo,
            status
        INTO
            v_tipo_fluxo,
            v_status_cod
        FROM
            documento
        WHERE
            documento_id = p_documento_id;
  --
        IF v_tipo_fluxo = 'ND' THEN
            v_status := '-';
        END IF;
  --
        IF v_tipo_fluxo = 'AP' THEN
            IF v_status_cod = 'PEND' THEN
                SELECT
                    COUNT(*)
                INTO v_qtd_aberto
                FROM
                    task
                WHERE
                        objeto_id = p_documento_id
                    AND tipo_task = 'DOC_ANALISE_MSG'
                    AND flag_fechado = 'N';
    --
                IF v_qtd_aberto = 0 THEN
                    v_status := 'Aguardando Consolidação';
                ELSE
                    v_status := 'Aguardando Aprovação';
                END IF;

            ELSIF v_status_cod = 'OK' THEN
                v_status := 'Aprovado';
            ELSIF v_status_cod = 'NOK' THEN
                v_status := 'Reprovado';
            END IF;
        END IF;
  --
        IF v_tipo_fluxo = 'CO' THEN
            IF v_status_cod = 'PEND' THEN
                v_status := 'Aguardando Comentários';
            ELSIF v_status_cod = 'OK' THEN
                v_status := 'Comentário Encerrado';
            END IF;
        END IF;
  --
        IF v_tipo_fluxo = 'CI' THEN
            IF v_status_cod = 'PEND' THEN
                v_status := 'Aguardando Ciência';
            ELSIF v_status_cod = 'OK' THEN
                v_status := 'Ciência Encerrada';
            END IF;
        END IF;
  --
        RETURN v_status;
    EXCEPTION
        WHEN OTHERS THEN
            v_status := 'ERRO';
            RETURN v_status;
    END status_retornar;
 --
 --
    FUNCTION status_task_retornar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/12/2004
  -- DESCRICAO: retorna texto com a descricao do status da task associada a um
  -- determinado documento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
        p_task_id IN task.task_id%TYPE
    ) RETURN VARCHAR2 AS

        v_status         VARCHAR2(100);
        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_tipo_fluxo     documento.tipo_fluxo%TYPE;
        v_flag_fechado   task.flag_fechado%TYPE;
        v_compl_fecham   task.compl_fecham%TYPE;
        v_tipo_objeto_id tipo_objeto.tipo_objeto_id%TYPE;
  --
    BEGIN
        v_status := NULL;
  --
        SELECT
            MAX(tipo_objeto_id)
        INTO v_tipo_objeto_id
        FROM
            tipo_objeto
        WHERE
            codigo = 'DOCUMENTO';
  --
        IF v_tipo_objeto_id IS NULL THEN
            RAISE v_exception;
        END IF;
  --
        SELECT
            d.tipo_fluxo,
            t.flag_fechado,
            t.compl_fecham
        INTO
            v_tipo_fluxo,
            v_flag_fechado,
            v_compl_fecham
        FROM
            task      t,
            documento d
        WHERE
                t.task_id = p_task_id
            AND t.objeto_id = d.documento_id
            AND t.tipo_objeto_id = v_tipo_objeto_id;
  --
        IF v_tipo_fluxo = 'ND' THEN
            v_status := '-';
        END IF;
  --
        IF v_tipo_fluxo = 'AP' THEN
            IF v_flag_fechado = 'N' THEN
                v_status := 'Aguardando Aprovação';
            ELSE
                IF v_compl_fecham = 'NOK' THEN
                    v_status := 'Reprovado';
                ELSIF v_compl_fecham = 'OK' THEN
                    v_status := 'Aprovado';
                ELSE
                    v_status := 'Encerrado';
                END IF;
            END IF;
        END IF;
  --
        IF v_tipo_fluxo = 'CO' THEN
            IF v_flag_fechado = 'N' THEN
                v_status := 'Aguardando Comentários';
            ELSE
                v_status := 'Comentário Encerrado';
            END IF;
        END IF;
  --
        IF v_tipo_fluxo = 'CI' THEN
            IF v_flag_fechado = 'N' THEN
                v_status := 'Aguardando Ciência';
            ELSE
                v_status := 'Ciência Encerrada';
            END IF;
        END IF;
  --
        RETURN v_status;
    EXCEPTION
        WHEN v_exception THEN
            v_status := 'ERRO';
            RETURN v_status;
        WHEN OTHERS THEN
            v_status := 'ERRO';
            RETURN v_status;
    END status_task_retornar;
 --
 --
    FUNCTION consolidado_verificar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/01/2005
  -- DESCRICAO: verifica se todas as versoes desse documento estao consolidadas.
  --  Retorna 1 caso esteja e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER AS

        v_retorno           INTEGER;
        v_qt                INTEGER;
        v_nome              documento.nome%TYPE;
        v_tipo_documento_id documento.tipo_documento_id%TYPE;
        v_job_id            documento.job_id%TYPE;
  --
    BEGIN
        v_retorno := 0;
  --
        SELECT
            tipo_documento_id,
            job_id,
            nome
        INTO
            v_tipo_documento_id,
            v_job_id,
            v_nome
        FROM
            documento
        WHERE
            documento_id = p_documento_id;
  --
  -- verifica se existem versoes desse documento nao consolidadas
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            documento
        WHERE
                job_id = v_job_id
            AND tipo_documento_id = v_tipo_documento_id
            AND nome = v_nome
            AND status = 'PEND';
  --
        IF v_qt = 0 THEN
            v_retorno := 1;
        END IF;
  --
        RETURN v_retorno;
    EXCEPTION
        WHEN OTHERS THEN
            v_retorno := 0;
            RETURN v_retorno;
    END consolidado_verificar;
 --
 --
    FUNCTION prim_arquivo_id_retornar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/05/2008
  -- DESCRICAO: retorna o id do primeiro arquivo associado ao documento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER AS
        v_retorno INTEGER;
        v_qt      INTEGER;
  --
    BEGIN
        v_retorno := NULL;
  --
        SELECT
            MIN(arquivo_id)
        INTO v_retorno
        FROM
            arquivo_documento
        WHERE
            documento_id = p_documento_id;
  --
        RETURN v_retorno;
    EXCEPTION
        WHEN OTHERS THEN
            v_retorno := NULL;
            RETURN v_retorno;
    END prim_arquivo_id_retornar;
 --
 --
    FUNCTION qtd_arquivo_retornar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/05/2008
  -- DESCRICAO: retorna a qtd de arquivos associados ao documento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER AS
        v_retorno INTEGER;
        v_qt      INTEGER;
  --
    BEGIN
        v_retorno := 0;
  --
        SELECT
            COUNT(*)
        INTO v_retorno
        FROM
            arquivo_documento
        WHERE
            documento_id = p_documento_id;
  --
        RETURN v_retorno;
    EXCEPTION
        WHEN OTHERS THEN
            v_retorno := 0;
            RETURN v_retorno;
    END qtd_arquivo_retornar;
 --
 --
    PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/09/2017
  -- DESCRICAO: Subrotina que gera o xml de DOCUMENTO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_documento_id IN documento.documento_id%TYPE,
        p_xml          OUT CLOB,
        p_erro_cod     OUT VARCHAR2,
        p_erro_msg     OUT VARCHAR2
    ) IS

        v_qt        INTEGER;
        v_exception EXCEPTION;
        v_xml       XMLTYPE;
        v_xml_aux1  XMLTYPE;
        v_xml_aux99 XMLTYPE;
        v_xml_doc   VARCHAR2(100);
  --
        CURSOR c_ar IS
        SELECT
            ad.arquivo_id,
            ar.nome_fisico,
            ar.nome_original,
            vo.caminho
            || '\'
            || vo.prefixo
            || '\'
            || to_char(vo.numero) volume
        FROM
            arquivo_documento ad,
            arquivo           ar,
            volume            vo
        WHERE
                ad.documento_id = p_documento_id
            AND ad.arquivo_id = ar.arquivo_id
            AND ar.volume_id = vo.volume_id
        ORDER BY
            ad.arquivo_id;
  --
        CURSOR c_ta IS
        SELECT
            pa.nome AS papel,
            ta.prioridade
        FROM
            task        ta,
            papel       pa,
            tipo_objeto tb
        WHERE
                ta.tipo_objeto_id = tb.tipo_objeto_id
            AND tb.codigo = 'DOCUMENTO'
            AND ta.objeto_id = p_documento_id
            AND ta.tipo_task = 'DOC_ANALISE_MSG'
            AND ta.papel_resp_id = pa.papel_id
        ORDER BY
            pa.nome;
  --
    BEGIN
        v_qt := 0;
        v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
        SELECT
            xmlconcat(XMLELEMENT(
                "documento_id",
                      dc.documento_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "numero_job",
                      jo.numero
            ),
                      XMLELEMENT(
                "tipo_fluxo",
                      util_pkg.desc_retornar('tipo_fluxo', dc.tipo_fluxo)
            ),
                      XMLELEMENT(
                "papel_resp",
                      pa.nome
            ),
                      XMLELEMENT(
                "criador",
                      pe.apelido
            ),
                      XMLELEMENT(
                "tipo_docum",
                      td.nome
            ),
                      XMLELEMENT(
                "nome",
                      dc.nome
            ),
                      XMLELEMENT(
                "versao",
                      dc.versao
            ),
                      XMLELEMENT(
                "data_versao",
                      data_hora_mostrar(dc.data_versao)
            ),
                      XMLELEMENT(
                "descricao",
                      dc.descricao
            ),
                      XMLELEMENT(
                "comentario",
                      dc.comentario
            ),
                      XMLELEMENT(
                "consolidacao",
                      dc.consolidacao
            ),
                      XMLELEMENT(
                "status",
                      status_retornar(dc.documento_id)
            ))
        INTO v_xml
        FROM
            documento      dc,
            tipo_documento td,
            job            jo,
            papel          pa,
            pessoa         pe
        WHERE
                dc.documento_id = p_documento_id
            AND dc.tipo_documento_id = td.tipo_documento_id
            AND dc.papel_resp_id = pa.papel_id
            AND dc.job_id = jo.job_id
            AND dc.usuario_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- monta FLUXO
  ------------------------------------------------------------
        v_xml_aux1 := NULL;
        FOR r_ta IN c_ta LOOP
            SELECT
                XMLAGG(XMLELEMENT(
                    "papel",
                       XMLELEMENT(
                        "nome",
                       r_ta.papel
                    ),
                       XMLELEMENT(
                        "prioridade",
                       r_ta.prioridade
                    )
                ))
            INTO v_xml_aux99
            FROM
                dual;
   --
            SELECT
                xmlconcat(v_xml_aux1, v_xml_aux99)
            INTO v_xml_aux1
            FROM
                dual;

        END LOOP;
  --
        SELECT
            XMLAGG(XMLELEMENT(
                "fluxo",
                   v_xml_aux1
            ))
        INTO v_xml_aux1
        FROM
            dual;
  --
        SELECT
            xmlconcat(v_xml, v_xml_aux1)
        INTO v_xml
        FROM
            dual;
  --
  ------------------------------------------------------------
  -- monta ARQUIVOS
  ------------------------------------------------------------
        v_xml_aux1 := NULL;
        FOR r_ar IN c_ar LOOP
            SELECT
                XMLAGG(XMLELEMENT(
                    "arquivo",
                       XMLELEMENT(
                        "arquivo_id",
                       r_ar.arquivo_id
                    ),
                       XMLELEMENT(
                        "nome_original",
                       r_ar.nome_original
                    ),
                       XMLELEMENT(
                        "nome_fisico",
                       r_ar.nome_fisico
                    ),
                       XMLELEMENT(
                        "volume",
                       r_ar.volume
                    )
                ))
            INTO v_xml_aux99
            FROM
                dual;
   --
            SELECT
                xmlconcat(v_xml_aux1, v_xml_aux99)
            INTO v_xml_aux1
            FROM
                dual;

        END LOOP;
  --
        SELECT
            XMLAGG(XMLELEMENT(
                "arquivos",
                   v_xml_aux1
            ))
        INTO v_xml_aux1
        FROM
            dual;
  --
        SELECT
            xmlconcat(v_xml, v_xml_aux1)
        INTO v_xml
        FROM
            dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "documento"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "documento",
                   v_xml
            ))
        INTO v_xml
        FROM
            dual;
  --
  ------------------------------------------------------------
  -- acrescenta o tipo de documento e converte para CLOB
  ------------------------------------------------------------
        SELECT
            v_xml_doc || v_xml.getclobval()
        INTO p_xml
        FROM
            dual;
  --
        p_erro_cod := '00000';
        p_erro_msg := 'Operação realizada com sucesso.';
  --
    EXCEPTION
        WHEN v_exception THEN
            NULL;
        WHEN OTHERS THEN
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

    END xml_gerar;
 --
--
END; -- DOCUMENTO_PKG



/
