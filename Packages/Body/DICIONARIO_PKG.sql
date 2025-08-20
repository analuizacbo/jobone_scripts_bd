--------------------------------------------------------
--  DDL for Package Body DICIONARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DICIONARIO_PKG" IS
 --
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 16/10/2024
  -- DESCRICAO: Inclusão de atributo no dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_observacao        IN VARCHAR2,
        p_flag_alterar      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS
        v_qt    INTEGER;
        v_exception EXCEPTION;
        v_ordem dicionario.ordem%TYPE;
  /*
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  */
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
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
        IF length(p_tipo) > 50 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O código não pode ter mais que 50 caracteres.';
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
        IF length(p_codigo) > 50 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O código não pode ter mais que 50 caracteres.';
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
        IF flag_validar(p_flag_alterar) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag alterar inválido.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verificacao integridade
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                upper(codigo) = upper(p_codigo)
            AND lower(tipo) = lower(p_tipo);

        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse código já existe para esse tipo';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                upper(codigo) = upper(p_codigo)
            AND ordem = v_ordem;

        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa ordem já existe para esse código';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
        INSERT INTO dicionario (
            tipo,
            codigo,
            descricao,
            ordem,
            obs,
            flag_alterar
        ) VALUES (
            lower(p_tipo),
            upper(TRIM(p_codigo)),
            TRIM(p_descricao),
            v_ordem,
            TRIM(p_observacao),
            TRIM(p_flag_alterar)
        );
  --
  /*
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := upper(TRIM(p_codigo));
  v_compl_histor   := TRIM(p_descricao) || ' - Ativo: ' || TRIM(p_flag_alterar);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'DICION_EMP',
                   'INCLUIR',
                   v_identif_objeto,
                   v_dicion_emp_id,
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
  */
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
  -- DESENVOLVEDOR: Ana Luiza            ProcessMind     DATA: 16/10/2024
  -- DESCRICAO: Alteracao de atributo do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_observacao        IN VARCHAR2,
        p_codigo_old        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt            INTEGER;
        v_exception EXCEPTION;
        v_ordem         dicionario.ordem%TYPE;
        v_descricao_old dicionario.descricao%TYPE;
        v_ordem_old     dicionario.ordem%TYPE;
        v_obs_old       dicionario.obs%TYPE;
  /*
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  */
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
        IF p_codigo_old IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O código atual do atributo deve ser informado.';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  --Verificacao de integridade
  ------------------------------------------------------------
  /*
  SELECT COUNT(1)
    INTO v_qt
    FROM dicionario
   WHERE lower(TRIM(tipo)) = lower(TRIM(p_tipo))
     AND upper(TRIM(codigo)) = upper(TRIM(p_codigo));
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse atributo não existe para ser alterado ' || lower(TRIM(p_tipo)) || '|' ||
                 upper(TRIM(p_codigo)) || '|' || v_ordem;
   RAISE v_exception;
  END IF;
  */
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                upper(codigo) = upper(p_codigo)
            AND lower(tipo) = lower(p_tipo)
            AND TRIM(descricao) = TRIM(p_descricao)
            AND ordem = v_ordem
            AND TRIM(obs) = TRIM(p_observacao);

        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse código já existe para esse tipo';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                upper(codigo) = upper(p_codigo)
            AND ordem = v_ordem
            AND TRIM(descricao) = TRIM(p_descricao)
            AND TRIM(obs) = TRIM(p_observacao);

        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa ordem já existe para esse código';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                lower(TRIM(tipo)) = lower(TRIM(p_tipo))
            AND upper(TRIM(codigo)) = upper(TRIM(p_codigo))
            AND flag_alterar = 'N';

        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo não tem permissão para ser alterado.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            TRIM(descricao),
            ordem,
            TRIM(obs)
        INTO
            v_descricao_old,
            v_ordem_old,
            v_obs_old
        FROM
            dicionario
        WHERE
                lower(tipo) = lower(p_tipo)
            AND upper(codigo) = upper(p_codigo_old);

        IF v_descricao_old <> trim(p_descricao) OR v_ordem_old <> v_ordem OR v_obs_old <> trim(p_observacao) OR p_codigo_old <> p_codigo
        THEN
            UPDATE dicionario
            SET
                ordem = v_ordem,
                codigo = TRIM(upper(p_codigo)),
                descricao = TRIM(p_descricao),
                obs = TRIM(p_observacao)
            WHERE
                    lower(tipo) = lower(p_tipo)
                AND upper(codigo) = upper(p_codigo_old)
                AND flag_alterar = 'S';

        ELSE
            UPDATE dicionario
            SET
                codigo = TRIM(upper(p_codigo))
            WHERE
                    lower(tipo) = lower(p_tipo)
                AND upper(codigo) = upper(p_codigo)
                AND flag_alterar = 'S';

        END IF;
  --
  /*
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := upper(TRIM(p_codigo));
  v_compl_histor   := TRIM(p_descricao) || ' - Ativo: ' || TRIM(p_flag_ativo);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'DICION_EMP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_dicion_emp_id,
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
  */
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
  -- DESENVOLVEDOR: Ana              ProcessMind     DATA: 16/10/2024
  -- DESCRICAO: Exclusao de atributo do dicionario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_codigo            IN VARCHAR2,
        p_tipo              IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS
        v_qt INTEGER;
        v_exception EXCEPTION;
  /*
  v_descricao    dicionario.descricao%TYPE;
  v_codigo       dicionario.codigo%TYPE;
  v_flag_alterar dicionario.flag_alterar%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  */
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
            dicionario
        WHERE
                lower(TRIM(tipo)) = lower(TRIM(p_tipo))
            AND upper(TRIM(codigo)) = upper(TRIM(p_codigo));
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo do dicionário não existe.';
            RAISE v_exception;
        END IF;
  --
  /*
  SELECT codigo,
         descricao,
         flag_alterar
    INTO v_codigo,
         v_descricao,
         v_flag_alterar
    FROM dicionario
   WHERE lower(TRIM(tipo)) = lower(TRIM(p_tipo))
     AND upper(TRIM(codigo)) = upper(TRIM(p_codigo));
   */
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            dicionario
        WHERE
                lower(TRIM(tipo)) = lower(TRIM(p_tipo))
            AND upper(TRIM(codigo)) = upper(TRIM(p_codigo))
            AND flag_alterar = 'S';

        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse atributo não tem permissão para ser excluído.';
            RAISE v_exception;
        END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM dicionario
        WHERE
                lower(TRIM(tipo)) = lower(TRIM(p_tipo))
            AND upper(TRIM(codigo)) = upper(TRIM(p_codigo))
            AND flag_alterar = 'S';
  --
  /*
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := upper(TRIM(v_grupo)) || '/' || upper(TRIM(v_codigo));
  v_compl_histor   := TRIM(v_descricao) || ' - Ativo: ' || TRIM(v_flag_ativo);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'DICION_EMP',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_dicion_emp_id,
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
  */
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
END; -- DICION_EMP_PKG



/
