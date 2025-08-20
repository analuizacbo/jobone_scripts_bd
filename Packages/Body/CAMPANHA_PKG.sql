--------------------------------------------------------
--  DDL for Package Body CAMPANHA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CAMPANHA_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/05/2016
  -- DESCRICAO: Inclusão de CAMPANHA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_cliente_id        IN campanha.cliente_id%TYPE,
        p_cod_ext_camp      IN campanha.cod_ext_camp%TYPE,
        p_nome              IN campanha.nome%TYPE,
        p_data_ini          IN VARCHAR2,
        p_data_fim          IN VARCHAR2,
        p_campanha_id       OUT NUMBER,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_campanha_id    campanha.campanha_id%TYPE;
        v_data_ini       campanha.data_ini%TYPE;
        v_data_fim       campanha.data_fim%TYPE;
        v_cliente        pessoa.nome%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        p_campanha_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAMPANHA_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            pessoa
        WHERE
                pessoa_id = p_cliente_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_nome) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da descrição é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            nome
        INTO v_cliente
        FROM
            pessoa
        WHERE
            pessoa_id = p_cliente_id;
  --
        IF TRIM(p_data_ini) IS NULL OR TRIM(p_data_fim) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do período é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_ini) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inicial inválida ('
                          || p_data_ini
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_fim) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data final inválida ('
                          || p_data_fim
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_data_ini := data_converter(p_data_ini);
        v_data_fim := data_converter(p_data_fim);
  --
        IF v_data_ini > v_data_fim THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A data inicial não pode ser maior que a data final.';
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
            campanha
        WHERE
                cliente_id = p_cliente_id
            AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse nome de campanha já existe para esse cliente.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_campanha.NEXTVAL
        INTO v_campanha_id
        FROM
            dual;
  --
        INSERT INTO campanha (
            campanha_id,
            cliente_id,
            nome,
            cod_ext_camp,
            data_ini,
            data_fim,
            flag_ativo
        ) VALUES (
            v_campanha_id,
            p_cliente_id,
            TRIM(p_nome),
            TRIM(p_cod_ext_camp),
            v_data_ini,
            v_data_fim,
            'S'
        );
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        campanha_pkg.xml_gerar(v_campanha_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(v_cliente)
                            || ' - '
                            || trim(p_nome);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CAMPANHA', 'INCLUIR', v_identif_objeto,
                        v_campanha_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        p_campanha_id := v_campanha_id;
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
    END adicionar;
 --
 --
    PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/05/2016
  -- DESCRICAO: Atualização de CAMPANHA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_campanha_id       IN campanha.campanha_id%TYPE,
        p_cod_ext_camp      IN campanha.cod_ext_camp%TYPE,
        p_nome              IN campanha.nome%TYPE,
        p_data_ini          IN VARCHAR2,
        p_data_fim          IN VARCHAR2,
        p_flag_ativo        IN campanha.flag_ativo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_data_ini       campanha.data_ini%TYPE;
        v_data_fim       campanha.data_fim%TYPE;
        v_cliente_id     pessoa.pessoa_id%TYPE;
        v_cliente        pessoa.nome%TYPE;
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
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            campanha ca,
            pessoa   pe
        WHERE
                ca.campanha_id = p_campanha_id
            AND ca.cliente_id = pe.pessoa_id
            AND pe.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa campanha não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAMPANHA_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            pe.pessoa_id,
            pe.nome
        INTO
            v_cliente_id,
            v_cliente
        FROM
            campanha ca,
            pessoa   pe
        WHERE
                ca.campanha_id = p_campanha_id
            AND ca.cliente_id = pe.pessoa_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_nome) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do nome é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_data_ini) IS NULL OR TRIM(p_data_fim) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do período é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_ini) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data inicial inválida ('
                          || p_data_ini
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF data_validar(p_data_fim) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Data final inválida ('
                          || p_data_fim
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_data_ini := data_converter(p_data_ini);
        v_data_fim := data_converter(p_data_fim);
  --
        IF v_data_ini > v_data_fim THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A data inicial não pode ser maior que a data final.';
            RAISE v_exception;
        END IF;
  --
        IF flag_validar(p_flag_ativo) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag ativo inválido.';
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
            campanha
        WHERE
                cliente_id = v_cliente_id
            AND campanha_id <> p_campanha_id
            AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa campanha já existe para esse cliente.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        campanha_pkg.xml_gerar(p_campanha_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE campanha
        SET
            nome = TRIM(p_nome),
            cod_ext_camp = TRIM(p_cod_ext_camp),
            data_ini = v_data_ini,
            data_fim = v_data_fim,
            flag_ativo = p_flag_ativo
        WHERE
            campanha_id = p_campanha_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        campanha_pkg.xml_gerar(p_campanha_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(v_cliente)
                            || ' - '
                            || trim(p_nome);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CAMPANHA', 'ALTERAR', v_identif_objeto,
                        p_campanha_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 11/05/2016
  -- DESCRICAO: Exclusão de CAMPANHA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_campanha_id       IN campanha.campanha_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_nome           campanha.nome%TYPE;
        v_cliente_id     pessoa.pessoa_id%TYPE;
        v_cliente        pessoa.nome%TYPE;
        v_lbl_jobs       VARCHAR2(100);
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            campanha ca,
            pessoa   pe
        WHERE
                ca.campanha_id = p_campanha_id
            AND ca.cliente_id = pe.pessoa_id
            AND pe.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa campanha não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CAMPANHA_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            pe.pessoa_id,
            pe.nome,
            ca.nome
        INTO
            v_cliente_id,
            v_cliente,
            v_nome
        FROM
            campanha ca,
            pessoa   pe
        WHERE
                ca.campanha_id = p_campanha_id
            AND ca.cliente_id = pe.pessoa_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job
        WHERE
                campanha_id = p_campanha_id
            AND ROWNUM = 1;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem '
                          || v_lbl_jobs
                          || ' associados a essa campanha.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        campanha_pkg.xml_gerar(p_campanha_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM campanha
        WHERE
            campanha_id = p_campanha_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(v_cliente)
                            || ' - '
                            || trim(v_nome);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CAMPANHA', 'EXCLUIR', v_identif_objeto,
                        p_campanha_id, v_compl_histor, NULL, 'N', NULL,
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
    PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 22/02/2017
  -- DESCRICAO: Subrotina que gera o xml da campanha para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_campanha_id IN campanha.campanha_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    ) IS

        v_qt        INTEGER;
        v_exception EXCEPTION;
        v_xml       XMLTYPE;
        v_xml_aux1  XMLTYPE;
        v_xml_aux99 XMLTYPE;
        v_xml_doc   VARCHAR2(100);
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
                "campanha_id",
                      ca.campanha_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "cliente",
                      cl.apelido
            ),
                      XMLELEMENT(
                "nome",
                      ca.nome
            ),
                      XMLELEMENT(
                "data_inicio",
                      data_mostrar(ca.data_ini)
            ),
                      XMLELEMENT(
                "data_termino",
                      data_mostrar(ca.data_fim)
            ),
                      XMLELEMENT(
                "ativo",
                      ca.flag_ativo
            ),
                      XMLELEMENT(
                "cod_ext_campanha",
                      ca.cod_ext_camp
            ))
        INTO v_xml
        FROM
            campanha ca,
            pessoa   cl
        WHERE
                ca.campanha_id = p_campanha_id
            AND ca.cliente_id = cl.pessoa_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "campanha"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "campanha",
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
END; -- CAMPANHA_PKG



/
