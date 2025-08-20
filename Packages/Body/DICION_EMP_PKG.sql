--------------------------------------------------------
--  DDL for Package Body DICION_EMP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DICION_EMP_PKG" IS
 --
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Inclusão de atributo no dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo             IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_dicion_emp_id     OUT dicion_emp.dicion_emp_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_dicion_emp_id  dicion_emp.dicion_emp_id%TYPE;
        v_ordem          dicion_emp.ordem%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
        p_dicion_emp_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_grupo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do grupo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_grupo) > 20 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O grupo não pode ter mais que 20 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF p_grupo NOT IN ( 'MATRIZ_CLAS' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Grupo inválido ('
                          || p_grupo
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_ordem) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da ordem é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF inteiro_validar(p_ordem) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_ordem := nvl(TO_NUMBER(p_ordem), 0);
  --
        IF v_ordem > 99999 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_codigo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do código é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_codigo) > 20 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O código não pode ter mais que 20 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_descricao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da descrição é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
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
            dicion_emp
        WHERE
                upper(grupo) = TRIM(upper(p_grupo))
            AND upper(codigo) = TRIM(upper(p_codigo))
            AND empresa_id = p_empresa_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse código já existe para esse grupo.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_dicion_emp.NEXTVAL
        INTO v_dicion_emp_id
        FROM
            dual;
  --
        INSERT INTO dicion_emp (
            dicion_emp_id,
            empresa_id,
            grupo,
            codigo,
            descricao,
            ordem,
            flag_ativo
        ) VALUES (
            v_dicion_emp_id,
            p_empresa_id,
            upper(TRIM(p_grupo)),
            upper(TRIM(p_codigo)),
            TRIM(p_descricao),
            v_ordem,
            TRIM(p_flag_ativo)
        );
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := upper(trim(p_grupo))
                            || '/'
                            || upper(trim(p_codigo));

        v_compl_histor := trim(p_descricao)
                          || ' - Ativo: '
                          || trim(p_flag_ativo);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DICION_EMP', 'INCLUIR', v_identif_objeto,
                        v_dicion_emp_id, v_compl_histor, NULL, 'N', NULL,
                        NULL, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        COMMIT;
        p_dicion_emp_id := v_dicion_emp_id;
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Alteracao de atributo do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_codigo            IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_ordem          dicion_emp.ordem%TYPE;
        v_grupo          dicion_emp.grupo%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicion_emp
        WHERE
                empresa_id = p_empresa_id
            AND dicion_emp_id = p_dicion_emp_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            grupo
        INTO v_grupo
        FROM
            dicion_emp
        WHERE
            dicion_emp_id = p_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_ordem) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da ordem é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF inteiro_validar(p_ordem) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_ordem := nvl(TO_NUMBER(p_ordem), 0);
  --
        IF v_ordem > 99999 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_codigo) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do código é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_codigo) > 20 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O código não pode ter mais que 20 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_descricao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da descrição é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
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
            dicion_emp
        WHERE
                upper(grupo) = TRIM(upper(v_grupo))
            AND upper(codigo) = TRIM(upper(p_codigo))
            AND empresa_id = p_empresa_id
            AND dicion_emp_id <> p_dicion_emp_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse código já existe para esse grupo.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE dicion_emp
        SET
            ordem = v_ordem,
            codigo = TRIM(upper(p_codigo)),
            descricao = TRIM(p_descricao),
            flag_ativo = TRIM(p_flag_ativo)
        WHERE
            dicion_emp_id = p_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := upper(trim(v_grupo))
                            || '/'
                            || upper(trim(p_codigo));

        v_compl_histor := trim(p_descricao)
                          || ' - Ativo: '
                          || trim(p_flag_ativo);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DICION_EMP', 'ALTERAR', v_identif_objeto,
                        p_dicion_emp_id, v_compl_histor, NULL, 'N', NULL,
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
    END atualizar;
 --
 --
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Exclusao de atributo do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_descricao      dicion_emp.descricao%TYPE;
        v_grupo          dicion_emp.grupo%TYPE;
        v_codigo         dicion_emp.codigo%TYPE;
        v_flag_ativo     dicion_emp.flag_ativo%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicion_emp
        WHERE
                empresa_id = p_empresa_id
            AND dicion_emp_id = p_dicion_emp_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            codigo,
            grupo,
            descricao,
            flag_ativo
        INTO
            v_codigo,
            v_grupo,
            v_descricao,
            v_flag_ativo
        FROM
            dicion_emp
        WHERE
            dicion_emp_id = p_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            brief_dicion_valor br
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    dicion_emp_val dv
                WHERE
                        dv.dicion_emp_id = p_dicion_emp_id
                    AND dv.dicion_emp_val_id = br.dicion_emp_val_id
            );
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário está sendo usado por Briefing.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM dicion_emp_val
        WHERE
            dicion_emp_id = p_dicion_emp_id;

        DELETE FROM dicion_emp
        WHERE
            dicion_emp_id = p_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := upper(trim(v_grupo))
                            || '/'
                            || upper(trim(v_codigo));

        v_compl_histor := trim(v_descricao)
                          || ' - Ativo: '
                          || trim(v_flag_ativo);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DICION_EMP', 'EXCLUIR', v_identif_objeto,
                        p_dicion_emp_id, v_compl_histor, NULL, 'N', NULL,
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
    END excluir;
 --
 --
    PROCEDURE valor_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Inclusão de valor no dicionario para um determinado atributo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_dicion_emp_val_id OUT dicion_emp_val.dicion_emp_val_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_dicion_emp_val_id dicion_emp_val.dicion_emp_val_id%TYPE;
        v_ordem             dicion_emp_val.ordem%TYPE;
        v_grupo             dicion_emp.grupo%TYPE;
        v_codigo            dicion_emp.codigo%TYPE;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
        p_dicion_emp_val_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicion_emp
        WHERE
                empresa_id = p_empresa_id
            AND dicion_emp_id = p_dicion_emp_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            codigo,
            grupo
        INTO
            v_codigo,
            v_grupo
        FROM
            dicion_emp
        WHERE
            dicion_emp_id = p_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_ordem) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da ordem é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF inteiro_validar(p_ordem) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_ordem := nvl(TO_NUMBER(p_ordem), 0);
  --
        IF v_ordem > 99999 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_descricao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da descrição é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
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
            dicion_emp_val
        WHERE
                upper(descricao) = TRIM(upper(p_descricao))
            AND dicion_emp_id = p_dicion_emp_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse valor/descrição já existe para esse atributo.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_dicion_emp_val.NEXTVAL
        INTO v_dicion_emp_val_id
        FROM
            dual;
  --
        INSERT INTO dicion_emp_val (
            dicion_emp_val_id,
            dicion_emp_id,
            descricao,
            ordem,
            flag_ativo
        ) VALUES (
            v_dicion_emp_val_id,
            p_dicion_emp_id,
            TRIM(p_descricao),
            v_ordem,
            TRIM(p_flag_ativo)
        );
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := upper(trim(v_grupo))
                            || '/'
                            || upper(trim(v_codigo))
                            || '/'
                            || trim(p_descricao);

        v_compl_histor := 'Ativo: ' || trim(p_flag_ativo);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DICION_EMP', 'ALTERAR', v_identif_objeto,
                        p_dicion_emp_id, v_compl_histor, NULL, 'N', NULL,
                        NULL, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        COMMIT;
        p_dicion_emp_val_id := v_dicion_emp_val_id;
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
    END valor_adicionar;
 --
 --
    PROCEDURE valor_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Atualização de valor do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_val_id IN dicion_emp_val.dicion_emp_val_id%TYPE,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_grupo          dicion_emp.grupo%TYPE;
        v_codigo         dicion_emp.codigo%TYPE;
        v_dicion_emp_id  dicion_emp_val.dicion_emp_id%TYPE;
        v_ordem          dicion_emp_val.ordem%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicion_emp_val
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse valor de atributo não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            dicion_emp_id
        INTO v_dicion_emp_id
        FROM
            dicion_emp_val
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
  --
        SELECT
            codigo,
            grupo
        INTO
            v_codigo,
            v_grupo
        FROM
            dicion_emp
        WHERE
            dicion_emp_id = v_dicion_emp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF rtrim(p_ordem) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da ordem é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF inteiro_validar(p_ordem) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        v_ordem := nvl(TO_NUMBER(p_ordem), 0);
  --
        IF v_ordem > 99999 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Ordem inválida ('
                          || p_ordem
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_descricao) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da descrição é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
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
            dicion_emp_val
        WHERE
                upper(descricao) = TRIM(upper(p_descricao))
            AND dicion_emp_id = v_dicion_emp_id
            AND dicion_emp_val_id <> p_dicion_emp_val_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse valor/descrição já existe para esse atributo.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE dicion_emp_val
        SET
            ordem = v_ordem,
            descricao = TRIM(p_descricao),
            flag_ativo = TRIM(p_flag_ativo)
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := upper(trim(v_grupo))
                            || '/'
                            || upper(trim(v_codigo))
                            || '/'
                            || trim(p_descricao);

        v_compl_histor := 'Ativo: ' || trim(p_flag_ativo);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'DICION_EMP', 'ALTERAR', v_identif_objeto,
                        v_dicion_emp_id, v_compl_histor, NULL, 'N', NULL,
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
    END valor_atualizar;
 --
 --
    PROCEDURE valor_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 14/10/2016
  -- DESCRICAO: Exclusão de valor do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_val_id IN dicion_emp_val.dicion_emp_val_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_grupo          dicion_emp.grupo%TYPE;
        v_codigo         dicion_emp.codigo%TYPE;
        v_descricao      dicion_emp_val.descricao%TYPE;
        v_flag_ativo     dicion_emp_val.flag_ativo%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
  --
    BEGIN
        v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'DICIONARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicion_emp_val
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse valor de atributo não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            di.codigo,
            di.grupo,
            dv.descricao,
            dv.flag_ativo
        INTO
            v_codigo,
            v_grupo,
            v_descricao,
            v_flag_ativo
        FROM
            dicion_emp     di,
            dicion_emp_val dv
        WHERE
                dv.dicion_emp_val_id = p_dicion_emp_val_id
            AND dv.dicion_emp_id = di.dicion_emp_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            brief_dicion_valor br
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário está sendo usado por Briefing.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM dicion_emp_val
        WHERE
            dicion_emp_val_id = p_dicion_emp_val_id;
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
    END valor_excluir;
 --
--
END; -- DICION_EMP_PKG



/
