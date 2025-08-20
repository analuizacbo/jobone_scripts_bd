--------------------------------------------------------
--  DDL for Package Body COMUNICADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "COMUNICADO_PKG" IS
 --
 --
    PROCEDURE adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 26/09/2023
  -- DESCRICAO: Inclusao de COMUNICADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN NUMBER,
        p_conteudo          IN comunicado.conteudo%TYPE,
        p_data_fim          IN VARCHAR2,
        p_data_inicio       IN VARCHAR2,
        p_ilustracao        IN VARCHAR2,
        p_texto_botao       IN VARCHAR2,
        p_tipo_comunicado   IN VARCHAR2,
        p_titulo            IN VARCHAR2,
        p_url               IN VARCHAR2,
        p_vetor_papel_id    IN VARCHAR2,
        p_comunicado_id     OUT comunicado.comunicado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_xml_atual      CLOB;
  --
        v_delimitador    CHAR(1);
        v_comunicado_id  comunicado.comunicado_id%TYPE;
        v_vetor_papel_id VARCHAR2(1000);
        v_papel_id_char  VARCHAR2(20);
        v_papel_id       papel.papel_id%TYPE;
        v_resultado      VARCHAR2(1000) := '';
  --
        v_data_fim       DATE;
        v_data_inicio    DATE;
    BEGIN
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_titulo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do título é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_tipo_comunicado) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do tipo de comunicado é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_conteudo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do conteúdo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_texto_botao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do texto botão é obrigatório.';
            RAISE v_exception;
        END IF;
  --
  /*
  IF TRIM(p_url) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do link é obrigatório.';
   RAISE v_exception;
  END IF;
  */
  --
        IF TRIM(p_data_inicio) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da data início é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_inicio) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inválida.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_data_fim) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da data fim é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_fim) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inválida.';
            RAISE v_exception;
        END IF;

        v_data_fim := data_converter(p_data_fim);
        v_data_inicio := data_converter(p_data_inicio);
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
        SELECT
            seq_comunicado.NEXTVAL
        INTO v_comunicado_id
        FROM
            dual;
  --
        INSERT INTO comunicado (
            comunicado_id,
            empresa_id,
            data_inicio,
            data_fim,
            tipo_comunicado,
            titulo,
            conteudo,
            url,
            texto_botao,
            ilustracao,
            status,
            usuario_autor_id,
            usuario_sessao_id,
            data_criacao,
            flag_lido_por_todos
        ) VALUES (
            v_comunicado_id,
            p_empresa_id,
            v_data_inicio,
            v_data_fim,
            p_tipo_comunicado,
            p_titulo,
            p_conteudo,
            p_url,
            TRIM(p_texto_botao),
            p_ilustracao,
            'PREP',
            p_usuario_sessao_id,
            p_usuario_sessao_id,
            sysdate,
            'N'
        );
  --
        v_delimitador := '|';
  --Caso venha 0 faz um vetor com todos os papeis
        IF trim(p_vetor_papel_id) = '0' THEN
            FOR r_papeis IN (
                SELECT
                    papel_id
                FROM
                    papel
                WHERE
                    empresa_id = p_empresa_id
            ) LOOP
                v_resultado := v_resultado
                               || r_papeis.papel_id
                               || v_delimitador;
            END LOOP;
   -- Remove o último delimitador
            v_vetor_papel_id := rtrim(v_resultado, v_delimitador);
        ELSE
            v_vetor_papel_id := trim(p_vetor_papel_id);
        END IF;
  --
        WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0 LOOP
            v_papel_id_char := prox_valor_retornar(v_vetor_papel_id, v_delimitador);
            v_papel_id := nvl(numero_converter(v_papel_id_char), 0);
            INSERT INTO comunicado_papel (
                comunicado_id,
                papel_id
            ) VALUES (
                v_comunicado_id,
                v_papel_id
            );
   --
        END LOOP;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(v_comunicado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(p_titulo);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'INCLUIR', v_identif_objeto,
                        v_comunicado_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        COMMIT;
        p_comunicado_id := v_comunicado_id;
        p_erro_cod := '00000';
        p_erro_msg := 'Operação realizada com sucesso.';
  --
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
    END; --adicionar
 --
 --
    PROCEDURE alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 26/09/2023
  -- DESCRICAO: Alteracao de COMUNICADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         04/10/2023  Adicionado verificação de ilustracao e imagem
  ---------------- -----------------------------------------------------------------------
     (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN NUMBER,
        p_comunicado_id       IN comunicado.comunicado_id%TYPE,
        p_arquivo_id          IN arquivo.arquivo_id%TYPE,
        p_conteudo            IN comunicado.conteudo%TYPE,
        p_data_fim            IN VARCHAR2,
        p_data_inicio         IN VARCHAR2,
        p_flag_lido_por_todos IN VARCHAR2,
        p_ilustracao          IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_texto_botao         IN VARCHAR2,
        p_tipo_comunicado     IN VARCHAR2,
        p_titulo              IN VARCHAR2,
        p_url                 IN VARCHAR2,
        p_vetor_papel_id      IN VARCHAR2,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    ) IS

        v_qt               INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto   historico.identif_objeto%TYPE;
        v_compl_histor     historico.complemento%TYPE;
        v_historico_id     historico.historico_id%TYPE;
        v_xml_antes        CLOB;
        v_xml_atual        CLOB;
  --
        v_usuario_autor_id comunicado.usuario_autor_id%TYPE;
        v_status_old       comunicado.status%TYPE;
        v_delimitador      CHAR(1);
        v_vetor_papel_id   VARCHAR2(1000);
        v_papel_id_char    VARCHAR2(20);
        v_papel_id         papel.papel_id%TYPE;
        v_resultado        VARCHAR2(1000) := '';
  --
        v_data_fim         DATE;
        v_data_inicio      DATE;
    BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comunicado não existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_titulo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do título é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_tipo_comunicado) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do tipo de comunicado é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_conteudo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do conteúdo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_texto_botao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do texto botão é obrigatório.';
            RAISE v_exception;
        END IF;
  --
  /*
  IF TRIM(p_url) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do link é obrigatório.';
   RAISE v_exception;
  END IF;
  */
  --
        IF TRIM(p_data_inicio) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da data início é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_inicio) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inválida.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_data_fim) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da data fim é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_fim) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inválida.';
            RAISE v_exception;
        END IF;
  /*
  --ALCBO_041023
  IF nvl(p_arquivo_id,0) <> 0 AND TRIM(p_ilustracao) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Por favor informe somente a imagem ou a ilustração';
   RAISE v_exception;
  END IF;
  */
  --
        v_data_fim := data_converter(p_data_fim);
        v_data_inicio := data_converter(p_data_inicio);
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
        DELETE FROM comunicado_papel
        WHERE
            comunicado_id = p_comunicado_id;
  --
  --
        v_delimitador := '|';
  --Caso venha 0 faz um vetor com todos os papeis
        IF trim(p_vetor_papel_id) = '0' THEN
            FOR r_papeis IN (
                SELECT
                    papel_id
                FROM
                    papel
                WHERE
                    empresa_id = p_empresa_id
            ) LOOP
                v_resultado := v_resultado
                               || r_papeis.papel_id
                               || v_delimitador;
            END LOOP;
   -- Remove o último delimitador
            v_vetor_papel_id := rtrim(v_resultado, v_delimitador);
        ELSE
            v_vetor_papel_id := trim(p_vetor_papel_id);
        END IF;
  ------------------------------------------------------------
  --Atualizacao de papeis para o comunicado
  ------------------------------------------------------------
        WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0 LOOP
            v_papel_id_char := prox_valor_retornar(v_vetor_papel_id, v_delimitador);
            v_papel_id := nvl(numero_converter(v_papel_id_char), 0);
            INSERT INTO comunicado_papel (
                comunicado_id,
                papel_id
            ) VALUES (
                p_comunicado_id,
                v_papel_id
            );
   --
        END LOOP;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            usuario_autor_id
        INTO v_usuario_autor_id
        FROM
            comunicado
        WHERE
                comunicado_id = p_comunicado_id
            AND empresa_id = p_empresa_id;
  --
  --
        SELECT
            status
        INTO v_status_old
        FROM
            comunicado c
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_status_old <> p_status THEN
            comunicado_pkg.alterar_status(p_usuario_sessao_id, p_empresa_id, 'N', p_comunicado_id, p_status,
                                         p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
        UPDATE comunicado
        SET
            arquivo_id = TRIM(p_arquivo_id),
            conteudo = p_conteudo,
            data_criacao = sysdate,
            data_fim = v_data_fim,
            data_inicio = v_data_inicio,
            empresa_id = p_empresa_id,
            flag_lido_por_todos = p_flag_lido_por_todos,
            ilustracao = TRIM(p_ilustracao),
            status = TRIM(p_status),
            texto_botao = TRIM(p_texto_botao),
            tipo_comunicado = TRIM(p_tipo_comunicado),
            titulo = TRIM(p_titulo),
            url = TRIM(p_url),
            usuario_autor_id = v_usuario_autor_id,
            usuario_sessao_id = p_usuario_sessao_id
        WHERE
                comunicado_id = p_comunicado_id
            AND empresa_id = p_empresa_id;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := p_titulo;
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'ALTERAR', v_identif_objeto,
                        p_comunicado_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    END; --alterar
 --
 --
    PROCEDURE excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 26/09/2023
  -- DESCRICAO: exclusao de COMUNICADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN comunicado.empresa_id%TYPE,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_xml_antes      CLOB;
        v_xml_atual      CLOB;
  --
        v_titulo         comunicado.titulo%TYPE;
    BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            MAX(titulo)
        INTO v_titulo
        FROM
            comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_titulo IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comunicado não existe.';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
        DELETE FROM comunicado_papel
        WHERE
            comunicado_id = p_comunicado_id;

        DELETE FROM comunicado_usu
        WHERE
            comunicado_id = p_comunicado_id;

        DELETE FROM arquivo_comunicado
        WHERE
            comunicado_id = p_comunicado_id;

        DELETE FROM comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(v_titulo);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'EXCLUIR', v_identif_objeto,
                        p_comunicado_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    END; --excluir
 --
 --
    PROCEDURE alterar_status
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 27/09/2019
  -- DESCRICAO: Subrotina altera status COMUNICADO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_cod_acao          IN tipo_acao.codigo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt              INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto  historico.identif_objeto%TYPE;
        v_compl_histor    historico.complemento%TYPE;
        v_historico_id    historico.historico_id%TYPE;
        v_xml_antes       CLOB;
        v_xml_atual       CLOB;
  --
        v_status_old      comunicado.status%TYPE;
        v_desc_status_old dicionario.descricao%TYPE;
        v_desc_status_new dicionario.descricao%TYPE;
        v_titulo          comunicado.titulo%TYPE;
    BEGIN
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
            comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse Comunicado não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            status,
            titulo
        INTO
            v_status_old,
            v_titulo
        FROM
            comunicado c
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF p_flag_commit = 'S' THEN
   -- So testa privilegio quando chamada e via interface.
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF p_cod_acao NOT IN ( 'ARQUI', 'PREP', 'PUBLI' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Código da ação inválido ('
                          || p_cod_acao
                          || ').';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- validações de status baseado no status atual
  ------------------------------------------------------------
        CASE v_status_old
            WHEN 'PREP' THEN
                IF p_cod_acao NOT IN ( 'PUBLI', 'ARQUI' ) THEN
                    p_erro_cod := '90001';
                    p_erro_msg := 'Status inválido. Só pode mudar para Publicado ou Arquivado quando o
                 status atual é Preparação.';
                    RAISE v_exception;
                END IF;
            WHEN 'PUBLI' THEN
                IF p_cod_acao NOT IN ( 'PREP', 'ARQUI' ) THEN
                    p_erro_cod := '90002';
                    p_erro_msg := 'Status inválido. Só pode mudar para Preparação ou Arquivado quando o
                 status atual é Publicado.';
                    RAISE v_exception;
                END IF;
            WHEN 'ARQUI' THEN
                IF p_cod_acao NOT IN ( 'PREP' ) THEN
                    p_erro_cod := '90003';
                    p_erro_msg := 'Status inválido. Só pode mudar para Preparação quando o status atual é
                Arquivado.';
                    RAISE v_exception;
                END IF;
        END CASE;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE comunicado
        SET
            status = p_cod_acao
        WHERE
                comunicado_id = p_comunicado_id
            AND empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
        SELECT
            descricao
        INTO v_desc_status_old
        FROM
            dicionario
        WHERE
                codigo = v_status_old
            AND tipo = 'status_comunicado';
  --
        SELECT
            descricao
        INTO v_desc_status_new
        FROM
            dicionario
        WHERE
                codigo = p_cod_acao
            AND tipo = 'status_comunicado';
  --
        v_identif_objeto := to_char(v_titulo);
        v_compl_histor := 'Status do Comunicado alterado de '
                          || v_desc_status_old
                          || ' para '
                          || v_desc_status_new
                          || ' do Comunicado #'
                          || p_comunicado_id;

        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'ALTERAR_STATUS', v_identif_objeto,
                        p_comunicado_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
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
    END; --alterar_status
 --
 --
    PROCEDURE marcar_como_lido
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 28/09/2019
  -- DESCRICAO: Subrotina que gera o xml da COMUNICADO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN comunicado.empresa_id%TYPE,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_flag_lido         IN comunicado.flag_lido_por_todos%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                   INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto       historico.identif_objeto%TYPE;
        v_compl_histor         historico.complemento%TYPE;
        v_historico_id         historico.historico_id%TYPE;
        v_xml_antes            CLOB;
        v_xml_atual            CLOB;
  --
        v_titulo               comunicado.titulo%TYPE;
        v_qt_usuarios_papel    NUMBER;
        v_qt_comunicados_papel NUMBER;
        v_flag_lido_por_todos  CHAR(1);
    BEGIN
        v_flag_lido_por_todos := 'N';
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            MAX(titulo)
        INTO v_titulo
        FROM
            comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_titulo IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comunicado não existe.';
            RAISE v_exception;
        END IF;
  /*
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COMUNICADO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  */
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF flag_validar(p_flag_lido) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag lido inválida.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        IF p_flag_lido = 'S' THEN
   --Conta usuarios admin e flag_admin
            SELECT
                COUNT(1)
            INTO v_qt
            FROM
                usuario us
            WHERE
                ( us.flag_admin = 'S'
                  OR us.flag_admin_sistema = 'S' )
                AND us.usuario_id = p_usuario_sessao_id;
   --Se nao for admin ou flag_admin insere
            IF v_qt = 0 THEN
                INSERT INTO comunicado_usu (
                    comunicado_id,
                    data_visualizacao,
                    usuario_id
                ) VALUES (
                    p_comunicado_id,
                    sysdate,
                    p_usuario_sessao_id
                );

            END IF;

        END IF;
  --Verifica se existe registro na comunicado_usu para aquele usuario
        SELECT
            MAX(usuario_id)
        INTO v_qt
        FROM
            comunicado_usu
        WHERE
            comunicado_id = p_comunicado_id;
  --
  --
        IF v_qt IS NOT NULL THEN
   --
            FOR r_papel IN (
                SELECT
                    papel_id
                FROM
                    papel
                WHERE
                    empresa_id = p_empresa_id
            ) LOOP
    -- Contar usuários por papel
                SELECT
                    COUNT(DISTINCT usuario_id)
                INTO v_qt_usuarios_papel
                FROM
                    usuario_papel
                WHERE
                    papel_id = r_papel.papel_id;
    -- Contar comunicados para esse papel
                SELECT
                    COUNT(DISTINCT cu.usuario_id)
                INTO v_qt_comunicados_papel
                FROM
                         comunicado_usu cu
                    JOIN usuario_papel up ON cu.usuario_id = up.usuario_id
                WHERE
                        cu.comunicado_id = p_comunicado_id
                    AND up.papel_id = r_papel.papel_id;
    -- Comparar as contagens e decidir a ação
                IF v_qt_usuarios_papel = v_qt_comunicados_papel THEN
     -- Se as contagens forem iguais, atualiza tab comunicado
                    v_flag_lido_por_todos := 'S';
                END IF;
    --
    --
                UPDATE comunicado
                SET
                    flag_lido_por_todos = v_flag_lido_por_todos
                WHERE
                        comunicado_id = p_comunicado_id
                    AND empresa_id = p_empresa_id;

            END LOOP;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        comunicado_pkg.xml_gerar(p_comunicado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(v_titulo);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'MARCAR_LIDO_TODOS', v_identif_objeto,
                        p_comunicado_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    END;
 --
 --
    PROCEDURE arquivo_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 03/10/2023
  -- DESCRICAO: Adicionar arquivo no COMUNICADO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_comunicado_id     IN arquivo_comunicado.comunicado_id%TYPE,
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
        v_exception EXCEPTION;
        v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            comunicado
        WHERE
            comunicado_id = p_comunicado_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comunicado não existe.';
            RAISE v_exception;
        END IF;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', p_comunicado_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
        SELECT
            MAX(tipo_arquivo_id)
        INTO v_tipo_arquivo_id
        FROM
            tipo_arquivo
        WHERE
                empresa_id = p_empresa_id
            AND codigo = 'COMUNICADO';
  --
        arquivo_pkg.adicionar(p_usuario_sessao_id, p_arquivo_id, p_volume_id, p_comunicado_id, v_tipo_arquivo_id,
                             p_nome_original, p_nome_fisico, p_descricao, p_mime_type, p_tamanho,
                             p_palavras_chave, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(p_nome_original);
        v_compl_histor := 'Anexação de arquivo no comunicado ('
                          || p_nome_original
                          || ')';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'ALTERAR', v_identif_objeto,
                        p_comunicado_id, v_compl_histor, NULL, 'N', NULL,
                        NULL, v_historico_id, p_erro_cod, p_erro_msg);
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
    END arquivo_adicionar;
 --
 --
    PROCEDURE arquivo_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza               ProcessMind     DATA: 03/10/2023
  -- DESCRICAO: Excluir arquivo do comunicado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
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
        v_exception EXCEPTION;
  --
        v_nome_original  arquivo.nome_original%TYPE;
        v_comunicado_id  comunicado.comunicado_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            comunicado         ce,
            arquivo_comunicado ac
        WHERE
                ac.arquivo_id = p_arquivo_id
            AND ac.comunicado_id = ce.comunicado_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse arquivo não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            ac.comunicado_id,
            ar.nome_original
        INTO
            v_comunicado_id,
            v_nome_original
        FROM
            arquivo_comunicado ac,
            arquivo            ar
        WHERE
                ac.arquivo_id = p_arquivo_id
            AND ac.arquivo_id = ar.arquivo_id;
  --
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMUNICADO_C', v_comunicado_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
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
  --
        v_identif_objeto := to_char(v_nome_original);
        v_compl_histor := 'Exclusão de arquivo do Comunicado ('
                          || v_nome_original
                          || ')';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMUNICADO', 'ALTERAR', v_identif_objeto,
                        v_comunicado_id, v_compl_histor, NULL, 'N', NULL,
                        NULL, v_historico_id, p_erro_cod, p_erro_msg);
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
    END arquivo_excluir;
 --
 --
    PROCEDURE xml_gerar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 28/09/2019
  -- DESCRICAO: Subrotina que gera o xml da COMUNICADO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
     (
        p_comunicado_id IN comunicado.comunicado_id%TYPE,
        p_xml           OUT CLOB,
        p_erro_cod      OUT VARCHAR2,
        p_erro_msg      OUT VARCHAR2
    ) IS
        v_exception EXCEPTION;
        v_xml     XMLTYPE;
        v_xml_doc VARCHAR2(100);
  --
    BEGIN
        v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
        SELECT
            xmlconcat(XMLELEMENT(
                "comunicado_id",
                      co.comunicado_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "data_criacao",
                      data_hora_mostrar(co.data_criacao)
            ),
                      XMLELEMENT(
                "data_fim",
                      data_hora_mostrar(co.data_fim)
            ),
                      XMLELEMENT(
                "lido_por_todos",
                      co.flag_lido_por_todos
            ),
                      XMLELEMENT(
                "status",
                      co.status
            ),
                      XMLELEMENT(
                "tipo_comunicado",
                      co.tipo_comunicado
            ),
                      XMLELEMENT(
                "titulo",
                      co.titulo
            ),
                      XMLELEMENT(
                "criado_por",
                      pe.nome
            ),
                      XMLELEMENT(
                "usu_sessao",
                      pe.nome
            ))
        INTO v_xml
        FROM
            comunicado co
            LEFT JOIN pessoa     pe ON co.usuario_autor_id = pe.usuario_id
        WHERE
            co.comunicado_id = p_comunicado_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "comunicado"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "comunicado",
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

    END; --COMUNICADO_PKG
END;


/
