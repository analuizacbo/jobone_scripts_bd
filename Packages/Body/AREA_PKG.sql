--------------------------------------------------------
--  DDL for Package Body AREA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "AREA_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/02/2011
  -- DESCRICAO: Inclusão de AREA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/02/2014  Novo parametro flag_briefing     
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN area.nome%TYPE,
        p_flag_briefing     IN VARCHAR2,
        p_modelo_briefing   IN area.modelo_briefing%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_area_id        area.area_id%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'AREA_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
        IF flag_validar(p_flag_briefing) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag briefing inválido.';
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
            area
        WHERE
                upper(nome) = upper(p_nome)
            AND empresa_id = p_empresa_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa área já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_area.NEXTVAL
        INTO v_area_id
        FROM
            dual;
  --
        INSERT INTO area (
            area_id,
            empresa_id,
            nome,
            flag_briefing,
            modelo_briefing
        ) VALUES (
            v_area_id,
            p_empresa_id,
            ltrim(rtrim(p_nome)),
            p_flag_briefing,
            p_modelo_briefing
        );
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        area_pkg.xml_gerar(v_area_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := p_nome;
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'AREA', 'INCLUIR', v_identif_objeto,
                        v_area_id, v_compl_histor, NULL, 'N', NULL,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/02/2011
  -- DESCRICAO: Atualização de AREA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/02/2014  Novo parametro flag_briefing     
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_area_id           IN area.area_id%TYPE,
        p_nome              IN area.nome%TYPE,
        p_flag_briefing     IN VARCHAR2,
        p_modelo_briefing   IN area.modelo_briefing%TYPE,
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
            area
        WHERE
                area_id = p_area_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa área não existe.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'AREA_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
        IF flag_validar(p_flag_briefing) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag briefing inválido.';
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
            area
        WHERE
                area_id <> p_area_id
            AND upper(nome) = upper(p_nome)
            AND empresa_id = p_empresa_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa área já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        area_pkg.xml_gerar(p_area_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE area
        SET
            nome = ltrim(rtrim(p_nome)),
            flag_briefing = p_flag_briefing,
            modelo_briefing = p_modelo_briefing
        WHERE
            area_id = p_area_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        area_pkg.xml_gerar(p_area_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := p_nome;
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'AREA', 'ALTERAR', v_identif_objeto,
                        p_area_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    PROCEDURE iniciativas_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Atualização de iniciativas associadas a AREA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --    
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_area_id                 IN area.area_id%TYPE,
        p_vetor_dicion_emp_val_id IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    ) IS

        v_qt                      INTEGER;
        v_exception EXCEPTION;
        v_delimitador             CHAR(1);
        v_vetor_dicion_emp_val_id LONG;
        v_identif_objeto          historico.identif_objeto%TYPE;
        v_compl_histor            historico.complemento%TYPE;
        v_historico_id            historico.historico_id%TYPE;
        v_nome                    area.nome%TYPE;
        v_dicion_emp_val_id       area_dicion_valor.dicion_emp_val_id%TYPE;
        v_xml_antes               CLOB;
        v_xml_atual               CLOB;
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
            area
        WHERE
                area_id = p_area_id
            AND empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa área não existe.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'AREA_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            nome
        INTO v_nome
        FROM
            area
        WHERE
            area_id = p_area_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        area_pkg.xml_gerar(p_area_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM area_dicion_valor
        WHERE
            area_id = p_area_id;
  --
        v_delimitador := '|';
        v_vetor_dicion_emp_val_id := p_vetor_dicion_emp_val_id;
  --
        WHILE nvl(length(rtrim(v_vetor_dicion_emp_val_id)), 0) > 0 LOOP
            v_dicion_emp_val_id := TO_NUMBER ( prox_valor_retornar(v_vetor_dicion_emp_val_id, v_delimitador) );
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                dicion_emp_val
            WHERE
                dicion_emp_val_id = v_dicion_emp_val_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Esse valor de atributo não existe '
                              || to_char(v_dicion_emp_val_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            INSERT INTO area_dicion_valor (
                area_id,
                dicion_emp_val_id
            ) VALUES (
                p_area_id,
                v_dicion_emp_val_id
            );

        END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        area_pkg.xml_gerar(p_area_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := v_nome;
        v_compl_histor := 'Alteração de iniciativas';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'AREA', 'ALTERAR', v_identif_objeto,
                        p_area_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    END iniciativas_atualizar;
 --
 --
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/02/2011
  -- DESCRICAO: Exclusão de AREA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/05/2015  Nova tabela papel_priv_area.
  -- Silvia            14/10/2016  Nova tabela area_dicion_valor.
  -- Silvia            25/09/2019  Consistencia de usuario.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_area_id           IN area.area_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_nome           area.nome%TYPE;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            MAX(nome)
        INTO v_nome
        FROM
            area
        WHERE
                area_id = p_area_id
            AND empresa_id = p_empresa_id;
  --
        IF v_nome IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa área não existe.';
            RAISE v_exception;
        END IF;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'AREA_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
            usuario
        WHERE
            area_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem usuários associados a essa área.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            papel
        WHERE
            area_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem papéis associados a essa área.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            cargo
        WHERE
            area_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem cargos associados a essa área.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            brief_area
        WHERE
            area_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem briefings associados a essa área.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            apontam_hora
        WHERE
            area_papel_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem apontamentos de horas associados a essa área (APONTAM_HORA).';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            apontam_data
        WHERE
            area_cargo_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem apontamentos de horas associados a essa área (APONTAM_DATA).';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            contrato_horas
        WHERE
            area_id = p_area_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existem horas de contrato associadas a essa área.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        area_pkg.xml_gerar(p_area_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM area_dicion_valor
        WHERE
            area_id = p_area_id;

        DELETE FROM papel_priv_area
        WHERE
            area_id = p_area_id;

        DELETE FROM area
        WHERE
            area_id = p_area_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := v_nome;
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'AREA', 'EXCLUIR', v_identif_objeto,
                        p_area_id, v_compl_histor, NULL, 'N', NULL,
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
  -- DESCRICAO: Subrotina que gera o xml da area para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_area_id  IN area.area_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    ) IS

        v_qt        INTEGER;
        v_exception EXCEPTION;
        v_xml       XMLTYPE;
        v_xml_aux1  XMLTYPE;
        v_xml_aux99 XMLTYPE;
        v_xml_doc   VARCHAR2(100);
  --
        CURSOR c_in IS
        SELECT
            dv.descricao
        FROM
            area_dicion_valor ar,
            dicion_emp_val    dv
        WHERE
                ar.area_id = p_area_id
            AND ar.dicion_emp_val_id = dv.dicion_emp_val_id
        ORDER BY
            dv.descricao;
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
                "area_id",
                      area_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "nome",
                      nome
            ),
                      XMLELEMENT(
                "afetada_briefing",
                      flag_briefing
            ))
        INTO v_xml
        FROM
            area
        WHERE
            area_id = p_area_id;
  --
  ------------------------------------------------------------
  -- monta INICIATIVAS
  ------------------------------------------------------------
        v_xml_aux1 := NULL;
        FOR r_in IN c_in LOOP
            SELECT
                xmlconcat(XMLELEMENT(
                    "iniciativa",
                          r_in.descricao
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
                "iniciativas",
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
  -- junta tudo debaixo de "area"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "area",
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
END; -- AREA_PKG



/
