--------------------------------------------------------
--  DDL for Package Body COMENTARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "COMENTARIO_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 04/06/2013
  -- DESCRICAO: Adiciona um comentario ao objeto especificado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/04/2015  Comentario de horas no job
  -- Silvia            25/07/2017  Integracao Comunicacao Visual
  -- Silvia            19/09/2019  Comentario em oportunidade
  -- Silvia            29/06/2021  Comentario mudou p/ CLOB
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_tipo_objeto       IN VARCHAR2,
        p_objeto_id         IN comentario.objeto_id%TYPE,
        p_classe            IN comentario.classe%TYPE,
        p_comentario_pai_id IN comentario.comentario_pai_id%TYPE,
        p_comentario        IN comentario.comentario%TYPE,
        p_comentario_id     OUT comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_comentario_id     comentario.comentario_id%TYPE;
        v_tipo_objeto_id    comentario.tipo_objeto_id%TYPE;
        v_comentario_pai_id comentario.comentario_pai_id%TYPE;
        v_objeto_pai_id     comentario.objeto_id%TYPE;
        v_classe_pai        comentario.classe%TYPE;
        v_tipo_objeto_pai   tipo_objeto.codigo%TYPE;
        v_nome_objeto       tipo_objeto.nome%TYPE;
        v_cod_acao          tipo_acao.codigo%TYPE;
        v_exception EXCEPTION;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_lbl_job           VARCHAR2(100);
  --
    BEGIN
        v_qt := 0;
        p_comentario_id := 0;
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
            MAX(tipo_objeto_id)
        INTO v_tipo_objeto_id
        FROM
            tipo_objeto
        WHERE
            codigo = p_tipo_objeto;
  --
        IF v_tipo_objeto_id IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse tipo de objeto não existe ('
                          || p_tipo_objeto
                          || ').';
            RAISE v_exception;
        END IF;
  --
        SELECT
            nome
        INTO v_nome_objeto
        FROM
            tipo_objeto
        WHERE
            tipo_objeto_id = v_tipo_objeto_id;
  --
        IF nvl(p_objeto_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O objeto do comentário não foi especificado.';
            RAISE v_exception;
        END IF;
  --
        IF TRIM(p_classe) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A classe do comentário não foi especificada.';
            RAISE v_exception;
        END IF;
  --
        IF p_classe NOT IN ( 'PRINCIPAL', 'BRIEFING', 'ENDERECAMENTO', 'CRONOGRAMA', 'HORAS',
                             'PARCELAS' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Classe do comentário inválida ('
                          || p_classe
                          || ').';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_comentario) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do comentário é obrigatório.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
        IF nvl(p_comentario_pai_id, 0) > 0 THEN
            SELECT
                co.comentario_pai_id,
                co.objeto_id,
                ti.codigo,
                co.classe
            INTO
                v_comentario_pai_id,
                v_objeto_pai_id,
                v_tipo_objeto_pai,
                v_classe_pai
            FROM
                comentario  co,
                tipo_objeto ti
            WHERE
                    co.comentario_id = p_comentario_pai_id
                AND co.tipo_objeto_id = ti.tipo_objeto_id
                AND co.classe = TRIM(p_classe);
   --
            IF v_comentario_pai_id IS NOT NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Não é possível adicionar um comentário nesse nível.';
                RAISE v_exception;
            END IF;
   --
            IF v_objeto_pai_id <> p_objeto_id OR v_tipo_objeto_pai <> p_tipo_objeto OR v_classe_pai <> trim(p_classe) THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Comentários relacionados devem pertencer ao mesmo objeto.';
                RAISE v_exception;
            END IF;

        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_comentario.NEXTVAL
        INTO v_comentario_id
        FROM
            dual;
  --
        INSERT INTO comentario (
            comentario_id,
            tipo_objeto_id,
            objeto_id,
            classe,
            usuario_id,
            comentario_pai_id,
            data_coment,
            comentario
        ) VALUES (
            v_comentario_id,
            v_tipo_objeto_id,
            p_objeto_id,
            TRIM(p_classe),
            p_usuario_sessao_id,
            zvl(p_comentario_pai_id, NULL),
            sysdate,
            TRIM(p_comentario)
        );
  -- insere o proprio autor para poder ocultar a conversa
        INSERT INTO coment_usuario (
            comentario_id,
            usuario_id,
            flag_ocultar
        ) VALUES (
            v_comentario_id,
            p_usuario_sessao_id,
            'N'
        );
  --
        IF p_tipo_objeto = 'JOB' THEN
            SELECT
                MAX(numero)
            INTO v_identif_objeto
            FROM
                job
            WHERE
                job_id = p_objeto_id;
   --
            IF p_classe = 'BRIEFING' THEN
                v_cod_acao := 'COMENTAR_BRIEF';
            ELSIF p_classe = 'ENDERECAMENTO' THEN
                v_cod_acao := 'COMENTAR_ENDER';
            ELSIF p_classe = 'CRONOGRAMA' THEN
                v_cod_acao := 'COMENTAR_CRONO';
            ELSIF p_classe = 'HORAS' THEN
                v_cod_acao := 'COMENTAR_HORA';
            ELSE
                v_cod_acao := 'COMENTAR';
            END IF;
   --
        ELSIF p_tipo_objeto = 'ORDEM_SERVICO' THEN
            v_identif_objeto := ordem_servico_pkg.numero_formatar(p_objeto_id);
            v_cod_acao := 'COMENTAR';
   --
        ELSIF p_tipo_objeto = 'CARTA_ACORDO' THEN
            v_identif_objeto := carta_acordo_pkg.numero_completo_formatar(p_objeto_id, 'S');
            v_cod_acao := 'COMENTAR';
   --
        ELSIF p_tipo_objeto = 'ORCAMENTO' THEN
            v_identif_objeto := orcamento_pkg.numero_formatar(p_objeto_id);
            v_cod_acao := 'COMENTAR';
   --
        ELSIF p_tipo_objeto = 'ADIANT_DESP' THEN
            v_identif_objeto := adiant_desp_pkg.numero_formatar(p_objeto_id, 'S');
            v_cod_acao := 'COMENTAR';
        ELSIF p_tipo_objeto = 'CONTRATO' THEN
            SELECT
                MAX(numero)
            INTO v_identif_objeto
            FROM
                contrato
            WHERE
                contrato_id = p_objeto_id;
   --
            IF p_classe = 'ENDERECAMENTO' THEN
                v_cod_acao := 'COMENTAR_ENDER';
            ELSIF p_classe = 'HORAS' THEN
                v_cod_acao := 'COMENTAR_HORA';
            ELSIF p_classe = 'PARCELAS' THEN
                v_cod_acao := 'COMENTAR_PARC';
            ELSE
                v_cod_acao := 'COMENTAR';
            END IF;

        ELSIF p_tipo_objeto = 'OPORTUNIDADE' THEN
            SELECT
                MAX(numero)
            INTO v_identif_objeto
            FROM
                oportunidade
            WHERE
                oportunidade_id = p_objeto_id;

            v_cod_acao := 'COMENTAR';
        ELSIF p_tipo_objeto = 'TAREFA' THEN
            v_identif_objeto := tarefa_pkg.numero_formatar(p_objeto_id);
            v_cod_acao := 'COMENTAR';
        ELSE
   -- demais
            v_identif_objeto := p_objeto_id;
            v_cod_acao := 'COMENTAR';
        END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
        IF p_tipo_objeto IN ( 'JOB', 'ORDEM_SERVICO' ) THEN
            it_controle_pkg.integrar('COMENTARIO_MCV_NOTIFICAR', p_empresa_id, v_comentario_id, NULL, p_erro_cod,
                                    p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
        v_compl_histor := substr(trim(p_comentario), 1, 100);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, p_tipo_objeto, v_cod_acao, v_identif_objeto,
                        p_objeto_id, v_compl_histor, to_char(v_comentario_id), 'N', NULL,
                        NULL, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        IF p_flag_commit = 'S' THEN
            COMMIT;
        END IF;
  --
        p_comentario_id := v_comentario_id;
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
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/06/2013
  -- DESCRICAO: Exclui um determinado comentario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_usuario_id     comentario.usuario_id%TYPE;
        v_tipo_objeto_id comentario.tipo_objeto_id%TYPE;
        v_objeto_id      comentario.objeto_id%TYPE;
        v_classe         comentario.classe%TYPE;
        v_comentario     comentario.comentario%TYPE;
        v_tipo_objeto    tipo_objeto.codigo%TYPE;
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
            comentario
        WHERE
            comentario_id = p_comentario_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comentário não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            usuario_id,
            tipo_objeto_id,
            objeto_id,
            classe,
            comentario
        INTO
            v_usuario_id,
            v_tipo_objeto_id,
            v_objeto_id,
            v_classe,
            v_comentario
        FROM
            comentario
        WHERE
            comentario_id = p_comentario_id;
  --
        SELECT
            codigo
        INTO v_tipo_objeto
        FROM
            tipo_objeto
        WHERE
            tipo_objeto_id = v_tipo_objeto_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'COMENTARIO_X', NULL, NULL, p_empresa_id) <> 1 THEN
   -- usuario nao tem privilegio
            IF p_usuario_sessao_id = v_usuario_id THEN
    -- o comentario eh do proprio usuario.
    -- Se nao tiver resposta e se for o ultimo, pode excluir.
                SELECT
                    COUNT(*)
                INTO v_qt
                FROM
                    comentario
                WHERE
                    comentario_pai_id = p_comentario_id;
    --
                IF v_qt > 0 THEN
                    p_erro_cod := '90000';
                    p_erro_msg := 'Comentário não pode ser excluído pois já tem resposta.';
                    RAISE v_exception;
                END IF;
    --
                SELECT
                    COUNT(*)
                INTO v_qt
                FROM
                    comentario
                WHERE
                        usuario_id = p_usuario_sessao_id
                    AND tipo_objeto_id = v_tipo_objeto_id
                    AND objeto_id = v_objeto_id
                    AND classe = v_classe
                    AND comentario_id > p_comentario_id;
    --
                IF v_qt > 0 THEN
                    p_erro_cod := '90000';
                    p_erro_msg := 'Apenas seu comentário mais recente pode ser excluído.';
                    RAISE v_exception;
                END IF;

            ELSE
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM coment_usuario
        WHERE
            comentario_id = p_comentario_id;

        DELETE FROM coment_usuario us
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    comentario co
                WHERE
                        co.comentario_pai_id = p_comentario_id
                    AND co.comentario_id = us.comentario_id
            );

        DELETE FROM comentario
        WHERE
            comentario_pai_id = p_comentario_id;

        DELETE FROM comentario
        WHERE
            comentario_id = p_comentario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  /*
    v_identif_objeto := v_tipo_objeto || '/' || TO_CHAR(v_objeto_id) || '/' || v_classe;
    v_compl_histor := SUBSTR(TRIM(v_comentario),1,100);
  --
    evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'COMENTARIO', 'EXCLUIR',
                     v_identif_objeto, p_comentario_id, v_compl_histor, NULL,
                     'N', NULL, NULL,
                     v_historico_id, p_erro_cod, p_erro_msg);
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
    PROCEDURE enderecados_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/02/2013
  -- DESCRICAO: Atualização de usuarios enderecados no comentario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/09/2015  Novo flag_ocultar na tabela coment_usuario
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_vetor_enderecados IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_delimitador       CHAR(1);
        v_vetor_enderecados LONG;
        v_usuario_id        usuario.usuario_id%TYPE;
        v_usuario_ori_id    comentario.usuario_id%TYPE;
        v_lbl_job           VARCHAR2(100);
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
            comentario
        WHERE
            comentario_id = p_comentario_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comentário não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            usuario_id
        INTO v_usuario_ori_id
        FROM
            comentario
        WHERE
            comentario_id = p_comentario_id;
  --
        v_delimitador := '|';
  ------------------------------------------------------------
  -- tratamento do vetor de enderecados
  ------------------------------------------------------------
        DELETE FROM coment_usuario
        WHERE
            comentario_id = p_comentario_id;
  --
        v_vetor_enderecados := p_vetor_enderecados;
  --
        WHILE nvl(length(rtrim(v_vetor_enderecados)), 0) > 0 LOOP
            v_usuario_id := TO_NUMBER ( prox_valor_retornar(v_vetor_enderecados, v_delimitador) );
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                coment_usuario
            WHERE
                    comentario_id = p_comentario_id
                AND usuario_id = v_usuario_id;
   --
            IF
                v_qt = 0
                AND v_usuario_id <> v_usuario_ori_id
            THEN
    -- novo usuario enderecado e nao eh o proprio autor
                INSERT INTO coment_usuario (
                    comentario_id,
                    usuario_id,
                    flag_ocultar
                ) VALUES (
                    p_comentario_id,
                    v_usuario_id,
                    'N'
                );

            END IF;

        END LOOP;
  --
  -- insere o proprio autor para poder ocultar a conversa
        INSERT INTO coment_usuario (
            comentario_id,
            usuario_id,
            flag_ocultar
        ) VALUES (
            p_comentario_id,
            v_usuario_ori_id,
            'N'
        );
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
    END enderecados_atualizar;
 --
 --
    PROCEDURE ocultar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/09/2015
  -- DESCRICAO: Oculta das conversas o comentario associado ao usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS
        v_qt INTEGER;
        v_exception EXCEPTION;
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
            comentario
        WHERE
            comentario_id = p_comentario_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse comentário não existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE coment_usuario
        SET
            flag_ocultar = 'S'
        WHERE
                comentario_id = p_comentario_id
            AND usuario_id = p_usuario_sessao_id;
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
    END ocultar;
 --
--
END; -- COMENTARIO_PKG



/
