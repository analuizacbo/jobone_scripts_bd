--------------------------------------------------------
--  DDL for Package Body DEPARTAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEPARTAMENTO_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 19/05/2016
  -- DESCRICAO: Inclusão de DEPARTAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN departamento.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt              INTEGER;
        v_exception EXCEPTION;
        v_departamento_id departamento.departamento_id%TYPE;
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
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DEPTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            departamento
        WHERE
                empresa_id = p_empresa_id
            AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse nome de departamento já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_departamento.NEXTVAL
        INTO v_departamento_id
        FROM
            dual;
  --
        INSERT INTO departamento (
            departamento_id,
            empresa_id,
            nome
        ) VALUES (
            v_departamento_id,
            p_empresa_id,
            TRIM(p_nome)
        );
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        departamento_pkg.xml_gerar(v_departamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(p_nome);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DEPARTAMENTO', 'INCLUIR', v_identif_objeto,
                        v_departamento_id, v_compl_histor, NULL, 'N', NULL,
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
    END adicionar;
 --
 --
    PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 19/05/2016
  -- DESCRICAO: Atualização de DEPARTAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_departamento_id   IN departamento.departamento_id%TYPE,
        p_nome              IN departamento.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
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
            departamento
        WHERE
                departamento_id = p_departamento_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse departamento não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DEPTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            departamento
        WHERE
                empresa_id = p_empresa_id
            AND departamento_id <> p_departamento_id
            AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse nome de departamento já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        departamento_pkg.xml_gerar(p_departamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE departamento
        SET
            nome = TRIM(p_nome)
        WHERE
            departamento_id = p_departamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        departamento_pkg.xml_gerar(p_departamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := trim(p_nome);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DEPARTAMENTO', 'ALTERAR', v_identif_objeto,
                        p_departamento_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 19/05/2016
  -- DESCRICAO: Exclusão de DEPARTAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_departamento_id   IN departamento.departamento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_nome           departamento.nome%TYPE;
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
            departamento
        WHERE
                departamento_id = p_departamento_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse departamento não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DEPTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            nome
        INTO v_nome
        FROM
            departamento
        WHERE
            departamento_id = p_departamento_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            usuario
        WHERE
                departamento_id = p_departamento_id
            AND ROWNUM = 1;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem usuários associados a esse departamento.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        departamento_pkg.xml_gerar(p_departamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM departamento
        WHERE
            departamento_id = p_departamento_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := v_nome;
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DEPARTAMENTO', 'EXCLUIR', v_identif_objeto,
                        p_departamento_id, v_compl_histor, NULL, 'N', NULL,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 24/08/2017
  -- DESCRICAO: Subrotina que gera o xml do departamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_departamento_id IN departamento.departamento_id%TYPE,
        p_xml             OUT CLOB,
        p_erro_cod        OUT VARCHAR2,
        p_erro_msg        OUT VARCHAR2
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
                "departamento_id",
                      departamento_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "nome",
                      nome
            ))
        INTO v_xml
        FROM
            departamento
        WHERE
            departamento_id = p_departamento_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "departamento"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "departamento",
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
END; -- DEPARTAMENTO_PKG



/
