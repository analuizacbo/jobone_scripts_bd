--------------------------------------------------------
--  DDL for Package Body ARQUIVO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ARQUIVO_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Inclusão de ARQUIVO. Nao faz o commit, pois essa procedure e' chamada por
  --    outras. O arquivo_id e' gerado pela interface e passado como parametro p/ a
  --    procedure.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/05/2009  Consistencia do tamanho do arquivo.
  -- Silvia            24/09/2012  Novo tipo de arquivo: NOTA_FISCAL.
  -- Silvia            07/06/2013  Novo tipo de arquivo: TAREFA.
  -- Silvia            08/07/2013  Tabela tipo_arquivo; atributo palavras_chave.
  -- Silvia            05/09/2014  Novo tipo de arquivo: CONTRATO.
  -- Silvia            27/07/2015  Novo tipo de arquivo: JOB.
  -- Silvia            08/09/2015  Novo tipo de arquivo: CARTA_ACORDO_ACEI.
  -- Silvia            10/09/2015  Consistencias de limites.
  -- Silvia            11/07/2016  Novo tipo de arquivo: EMPRESA.
  -- Silvia            21/07/2016  Novo tipo de arquivo: CARTA_ACORDO_ORCAM.
  -- Silvia            18/07/2019  Novos tipos arquivo: OPORTUNIDADE/CENARIO
  -- Silvia            16/06/2020  Novo tipo de arquivo: ORCAMENTO
  -- Ana Luiza         05/10/2023  Novo tipo de arquivo: COMUNICADO
  -- Rafael            12/06/2025  Novo parametro adicionado na tabela ARQUIVO_PESSOA
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_objeto_id         IN NUMBER,
        p_tipo_arquivo_id   IN arquivo.tipo_arquivo_id%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_descricao         IN VARCHAR2,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt            INTEGER;
        v_exception EXCEPTION;
        v_status_volume volume.status%TYPE;
        v_cod_arquivo   tipo_arquivo.codigo%TYPE;
        v_tam_max_arq   tipo_arquivo.tam_max_arq%TYPE;
        v_qtd_max_arq   tipo_arquivo.qtd_max_arq%TYPE;
        v_extensoes     tipo_arquivo.extensoes%TYPE;
        v_extensao      VARCHAR2(200);
        v_qtd_arq       NUMBER(10);
  --
    BEGIN
        v_qt := 0;
        v_qtd_arq := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            volume
        WHERE
            volume_id = p_volume_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse volume não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            status
        INTO v_status_volume
        FROM
            volume
        WHERE
            volume_id = p_volume_id;
  --
        IF v_status_volume <> 'A' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse volume não está ativo.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            tipo_arquivo
        WHERE
            tipo_arquivo_id = p_tipo_arquivo_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse tipo de arquivo não existe ('
                          || to_char(p_tipo_arquivo_id)
                          || ').';
            RAISE v_exception;
        END IF;
  --
        SELECT
            codigo,
            tam_max_arq,
            qtd_max_arq,
            extensoes
        INTO
            v_cod_arquivo,
            v_tam_max_arq,
            v_qtd_max_arq,
            v_extensoes
        FROM
            tipo_arquivo
        WHERE
            tipo_arquivo_id = p_tipo_arquivo_id;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            arquivo
        WHERE
            arquivo_id = p_arquivo_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse identificador de arquivo já existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- verifica a qtd atual de arquivos ja anexados ao objeto
  ------------------------------------------------------------
        IF v_cod_arquivo = 'PESSOA' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_pessoa ap,
                arquivo        ar
            WHERE
                    ap.pessoa_id = p_objeto_id
                AND ap.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'DOCUMENTO' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_documento ad,
                arquivo           ar
            WHERE
                    ad.documento_id = p_objeto_id
                AND ad.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'TASK' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_task ak,
                arquivo      ar
            WHERE
                    ak.task_id = p_objeto_id
                AND ak.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'TAREFA' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_tarefa af,
                arquivo        ar
            WHERE
                    af.tarefa_id = p_objeto_id
                AND af.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo IN ( 'CARTA_ACORDO', 'CARTA_ACORDO_ACEI', 'CARTA_ACORDO_ORCAM' ) THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_carta ac,
                arquivo       ar
            WHERE
                    ac.carta_acordo_id = p_objeto_id
                AND ac.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'ORDEM_SERVICO' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_os ao,
                arquivo    ar
            WHERE
                    ao.ordem_servico_id = p_objeto_id
                AND ao.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'NOTA_FISCAL' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_nf an,
                arquivo    ar
            WHERE
                    an.nota_fiscal_id = p_objeto_id
                AND an.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'CONTRATO' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_contrato ac,
                arquivo          ar
            WHERE
                    ac.contrato_id = p_objeto_id
                AND ac.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'CONTRATO_FISICO' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_contrato_fisico ac,
                arquivo                 ar
            WHERE
                    ac.contrato_fisico_id = p_objeto_id
                AND ac.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --
        ELSIF v_cod_arquivo = 'JOB' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_job aj,
                arquivo     ar
            WHERE
                    aj.job_id = p_objeto_id
                AND aj.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;

        ELSIF v_cod_arquivo = 'EMPRESA' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_empresa ae,
                arquivo         ar
            WHERE
                    ae.empresa_id = p_objeto_id
                AND ae.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;

        ELSIF v_cod_arquivo = 'OPORTUNIDADE' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_oportunidade ao,
                arquivo              ar
            WHERE
                    ao.oportunidade_id = p_objeto_id
                AND ao.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;

        ELSIF v_cod_arquivo = 'CENARIO' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_cenario ac,
                arquivo         ar
            WHERE
                    ac.cenario_id = p_objeto_id
                AND ac.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;

        ELSIF v_cod_arquivo LIKE 'ORCAMENTO%' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_orcamento ao,
                arquivo           ar
            WHERE
                    ao.orcamento_id = p_objeto_id
                AND ao.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;
   --ALCBO_051023
        ELSIF v_cod_arquivo LIKE 'COMUNICADO%' THEN
            SELECT
                COUNT(*)
            INTO v_qtd_arq
            FROM
                arquivo_comunicado ao,
                arquivo            ar
            WHERE
                    ao.comunicado_id = p_objeto_id
                AND ao.arquivo_id = ar.arquivo_id
                AND ar.tipo_arquivo_id = p_tipo_arquivo_id;

        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF nvl(p_objeto_id, 0) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A identificação do objeto associado ao arquivo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_nome_original) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do nome original do arquivo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_nome_fisico) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_descricao) > 200 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A descrição do arquivo não pode ter mais que 200 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF nvl(p_tamanho, 0) <= 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Tamanho do arquivo inválido ('
                          || to_char(p_tamanho)
                          || ').';
            RAISE v_exception;
        END IF;
  --
        IF length(p_palavras_chave) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'As palavras-chave não podem ter mais que 500 caracteres.';
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
  -- atualizacao do banco
  ------------------------------------------------------------
        INSERT INTO arquivo (
            arquivo_id,
            volume_id,
            usuario_alt_id,
            tipo_arquivo_id,
            data_criacao,
            nome_original,
            nome_fisico,
            descricao,
            mime_type,
            tamanho,
            palavras_chave
        ) VALUES (
            p_arquivo_id,
            p_volume_id,
            p_usuario_sessao_id,
            p_tipo_arquivo_id,
            sysdate,
            TRIM(p_nome_original),
            p_nome_fisico,
            TRIM(p_descricao),
            p_mime_type,
            p_tamanho,
            TRIM(p_palavras_chave)
        );
  --
        IF v_cod_arquivo = 'PESSOA' THEN
            INSERT INTO arquivo_pessoa (
                arquivo_id,
                pessoa_id,
                data_hora   --RP_120625
            ) VALUES (
                p_arquivo_id,
                p_objeto_id,
                sysdate
            );
   --
        ELSIF v_cod_arquivo = 'DOCUMENTO' THEN
            INSERT INTO arquivo_documento (
                arquivo_id,
                documento_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'TASK' THEN
            INSERT INTO arquivo_task (
                arquivo_id,
                task_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'TAREFA' THEN
            INSERT INTO arquivo_tarefa (
                arquivo_id,
                tarefa_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo IN ( 'CARTA_ACORDO', 'CARTA_ACORDO_ACEI', 'CARTA_ACORDO_ORCAM' ) THEN
            INSERT INTO arquivo_carta (
                arquivo_id,
                carta_acordo_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'ORDEM_SERVICO' THEN
            INSERT INTO arquivo_os (
                arquivo_id,
                ordem_servico_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'NOTA_FISCAL' THEN
            INSERT INTO arquivo_nf (
                arquivo_id,
                nota_fiscal_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'CONTRATO' THEN
            INSERT INTO arquivo_contrato (
                arquivo_id,
                contrato_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'CONTRATO_FISICO' THEN
            INSERT INTO arquivo_contrato_fisico (
                arquivo_id,
                contrato_fisico_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'JOB' THEN
            INSERT INTO arquivo_job (
                arquivo_id,
                job_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'EMPRESA' THEN
            INSERT INTO arquivo_empresa (
                arquivo_id,
                empresa_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'OPORTUNIDADE' THEN
            INSERT INTO arquivo_oportunidade (
                arquivo_id,
                oportunidade_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo = 'CENARIO' THEN
            INSERT INTO arquivo_cenario (
                arquivo_id,
                cenario_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --
        ELSIF v_cod_arquivo LIKE 'ORCAMENTO%' THEN
            INSERT INTO arquivo_orcamento (
                arquivo_id,
                orcamento_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );
   --ALCBO_051023
        ELSIF v_cod_arquivo LIKE 'COMUNICADO%' THEN
            INSERT INTO arquivo_comunicado (
                arquivo_id,
                comunicado_id
            ) VALUES (
                p_arquivo_id,
                p_objeto_id
            );

        END IF;
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

    END adicionar;
 --
 --
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Exclusão de ARQUIVO. Nao faz o commit, pois essa procedure e' chamada por
  --    outras.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/09/2012  Novo tipo de arquivo: NOTA_FISCAL.
  -- Silvia            07/06/2013  Novo tipo de arquivo: TAREFA.
  -- Silvia            05/09/2014  Novo tipo de arquivo: CONTRATO.
  -- Silvia            27/07/2015  Novo tipo de arquivo: JOB.
  -- Silvia            08/09/2015  Novo tipo de arquivo: CARTA_ACORDO_ACEI.
  -- Silvia            11/07/2016  Novo tipo de arquivo: EMPRESA.
  -- Silvia            21/07/2016  Novo tipo de arquivo: CARTA_ACORDO_ORCAM.
  -- Silvia            18/07/2019  Novos tipos arquivo: OPORTUNIDADE/CENARIO
  -- Silvia            16/06/2020  Novo tipo de arquivo: ORCAMENTO
  -- Ana Luiza         05/10/2023  Novo tipo de arquivo: COMUNICADO
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS
        v_qt          INTEGER;
        v_exception EXCEPTION;
        v_cod_arquivo tipo_arquivo.codigo%TYPE;
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
            arquivo
        WHERE
            arquivo_id = p_arquivo_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse arquivo não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            ta.codigo
        INTO v_cod_arquivo
        FROM
            arquivo      ar,
            tipo_arquivo ta
        WHERE
                ar.arquivo_id = p_arquivo_id
            AND ar.tipo_arquivo_id = ta.tipo_arquivo_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        IF v_cod_arquivo = 'PESSOA' THEN
            DELETE FROM arquivo_pessoa
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'DOCUMENTO' THEN
            DELETE FROM arquivo_documento
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'TASK' THEN
            DELETE FROM arquivo_task
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'TAREFA' THEN
            DELETE FROM arquivo_tarefa
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo IN ( 'CARTA_ACORDO', 'CARTA_ACORDO_ACEI', 'CARTA_ACORDO_ORCAM' ) THEN
            DELETE FROM arquivo_carta
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'ORDEM_SERVICO' THEN
            DELETE FROM arquivo_os
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'NOTA_FISCAL' THEN
            DELETE FROM arquivo_nf
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'CONTRATO' THEN
            DELETE FROM arquivo_contrato
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'CONTRATO_FISICO' THEN
            DELETE FROM arquivo_contrato_fisico
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'JOB' THEN
            DELETE FROM arquivo_job
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'EMPRESA' THEN
            DELETE FROM arquivo_empresa
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'OPORTUNIDADE' THEN
            DELETE FROM arquivo_oportunidade
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo = 'CENARIO' THEN
            DELETE FROM arquivo_cenario
            WHERE
                arquivo_id = p_arquivo_id;

        ELSIF v_cod_arquivo LIKE 'ORCAMENTO%' THEN
            DELETE FROM arquivo_orcamento
            WHERE
                arquivo_id = p_arquivo_id;
   --ALCBO_051023
        ELSIF v_cod_arquivo LIKE 'COMUNICADO%' THEN
            DELETE FROM arquivo_comunicado
            WHERE
                arquivo_id = p_arquivo_id;

        END IF;
  --
        DELETE FROM arquivo
        WHERE
            arquivo_id = p_arquivo_id;
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

    END excluir;
 --
 --
    PROCEDURE palavras_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/08/2013
  -- DESCRICAO: Atualização das palavras indexadas do arquivo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_palavras_arquivo  IN CLOB,
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
            arquivo
        WHERE
            arquivo_id = p_arquivo_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse arquivo não existe.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE arquivo
        SET
            palavras_arquivo = p_palavras_arquivo
        WHERE
            arquivo_id = p_arquivo_id;
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
    END palavras_atualizar;
 --
 --
    PROCEDURE id_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Gera o proximo id de arquivo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_arquivo_id OUT arquivo.arquivo_id%TYPE,
        p_erro_cod   OUT VARCHAR2,
        p_erro_msg   OUT VARCHAR2
    ) IS
        v_qt INTEGER;
        v_exception EXCEPTION;
  --
    BEGIN
        p_arquivo_id := 0;
  --
        SELECT
            seq_arquivo.NEXTVAL
        INTO p_arquivo_id
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

    END id_gerar;
 --
--
END; -- ARQUIVO_PKG

/
