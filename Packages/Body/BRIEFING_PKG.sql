--------------------------------------------------------
--  DDL for Package Body BRIEFING_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "BRIEFING_PKG" IS
 --
    PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Inclusão de BRIEFING
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            06/03/2012  Modelo do briefing passou a vir do tipo de job.
  -- Silvia            14/01/2014  Nova tabela para armazenar o historico e motivos.
  --                               Nova tabela de areas envolvidas.
  -- Silvia            14/05/2015  Metadados de briefing
  -- Silvia            04/01/2016  Novo campo status.
  -- Silvia            20/10/2016  Copia matriz de classif do briefing anterior.
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN briefing.job_id%TYPE,
        p_vetor_area_id     IN VARCHAR2,
        p_briefing_id       OUT briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                 INTEGER;
        v_exception EXCEPTION;
        v_briefing_id        briefing.briefing_id%TYPE;
        v_briefing_ant_id    briefing.briefing_id%TYPE;
        v_num_briefing       briefing.numero%TYPE;
        v_requisicao_cliente briefing.requisicao_cliente%TYPE;
        v_status_brief       briefing.status%TYPE;
        v_brief_hist_id      brief_hist.brief_hist_id%TYPE;
        v_motivo             brief_hist.motivo%TYPE;
        v_numero_job         job.numero%TYPE;
        v_status_job         job.status%TYPE;
        v_budget             job.budget%TYPE;
        v_descricao_cliente  job.descricao_cliente%TYPE;
        v_tipo_job_id        job.tipo_job_id%TYPE;
        v_identif_objeto     historico.identif_objeto%TYPE;
        v_compl_histor       historico.complemento%TYPE;
        v_historico_id       historico.historico_id%TYPE;
        v_modelo_briefing    tipo_job.modelo_briefing%TYPE;
        v_delimitador        CHAR(1);
        v_vetor_area_id      VARCHAR2(1000);
        v_area_id            area.area_id%TYPE;
        v_lbl_job            VARCHAR2(100);
        v_lbl_brief          VARCHAR2(100);
        v_flag_budget_obrig  VARCHAR2(10);
        v_cronograma_id      item_crono.cronograma_id%TYPE;
        v_item_crono_id      item_crono.item_crono_id%TYPE;
        v_xml_atual          CLOB;
  --
    BEGIN
        v_qt := 0;
        p_briefing_id := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
        v_flag_budget_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BUDGET_OBRIGATORIO');
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
        IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', p_job_id, NULL, p_empresa_id) <> 1 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
                RAISE v_exception;
            END IF;
        END IF;
  --
        SELECT
            jo.numero,
            jo.status,
            jo.budget,
            jo.tipo_job_id,
            tj.modelo_briefing,
            jo.descricao_cliente
        INTO
            v_numero_job,
            v_status_job,
            v_budget,
            v_tipo_job_id,
            v_modelo_briefing,
            v_descricao_cliente
        FROM
            job      jo,
            tipo_job tj
        WHERE
                jo.job_id = p_job_id
            AND jo.tipo_job_id = tj.tipo_job_id;
  --
        IF v_status_job NOT IN ( 'ANDA', 'PREP' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF
            v_flag_budget_obrig = 'S'
            AND nvl(v_budget, 0) = 0
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O budget do '
                          || v_lbl_job
                          || ' deve ser informado antes da criação do '
                          || v_lbl_brief
                          || '.';
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
            briefing
        WHERE
                job_id = p_job_id
            AND status NOT IN ( 'ARQUI' );
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Existe '
                          || v_lbl_brief
                          || ' que ainda não foi aprovado.';
            RAISE v_exception;
        END IF;
  --
        v_briefing_ant_id := ultimo_retornar(p_job_id);
        v_requisicao_cliente := NULL;
  --
        IF nvl(v_briefing_ant_id, 0) > 0 THEN
            SELECT
                requisicao_cliente
            INTO v_requisicao_cliente
            FROM
                briefing
            WHERE
                briefing_id = v_briefing_ant_id;
   --
            v_motivo := 'Revisão da versão anterior';
        ELSE
            v_motivo := 'Versão inicial';
        END IF;
  --
        IF v_requisicao_cliente IS NULL THEN
   -- nao acho nada. Pega modelo
            v_requisicao_cliente := v_modelo_briefing;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            nvl(MAX(numero),
                0) + 1
        INTO v_num_briefing
        FROM
            briefing
        WHERE
            job_id = p_job_id;
  --
        SELECT
            seq_briefing.NEXTVAL
        INTO v_briefing_id
        FROM
            dual;
  --
        INSERT INTO briefing (
            briefing_id,
            job_id,
            usuario_id,
            numero,
            data_requisicao,
            requisicao_cliente,
            status,
            data_status
        ) VALUES (
            v_briefing_id,
            p_job_id,
            p_usuario_sessao_id,
            v_num_briefing,
            sysdate,
            v_requisicao_cliente,
            'PREP',
            sysdate
        );
  --
  -- grava historico do novo briefing
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            v_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            v_motivo,
            NULL
        );
  --
  ------------------------------------------------------------
  -- tratamento do vetor de areas
  ------------------------------------------------------------
        v_delimitador := '|';
        v_vetor_area_id := p_vetor_area_id;
  --
        WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0 LOOP
            v_area_id := TO_NUMBER ( prox_valor_retornar(v_vetor_area_id, v_delimitador) );
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                area
            WHERE
                    area_id = v_area_id
                AND empresa_id = p_empresa_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Essa área não existe ou não pertence a essa empresa ('
                              || to_char(v_area_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            INSERT INTO brief_area (
                briefing_id,
                area_id
            ) VALUES (
                v_briefing_id,
                v_area_id
            );

        END LOOP;
  --
  --
  ------------------------------------------------------------
  -- criacao de metadados do briefing
  ------------------------------------------------------------
        IF nvl(v_briefing_ant_id, 0) > 0 THEN
   -- copia metadados do briefing anterior
            INSERT INTO brief_atributo_valor (
                briefing_id,
                metadado_id,
                valor_atributo
            )
                SELECT
                    v_briefing_id,
                    metadado_id,
                    valor_atributo
                FROM
                    brief_atributo_valor
                WHERE
                    briefing_id = v_briefing_ant_id;
   --
   -- copia matriz do briefing anterior     
            INSERT INTO brief_dicion_valor (
                briefing_id,
                dicion_emp_val_id
            )
                SELECT
                    v_briefing_id,
                    dicion_emp_val_id
                FROM
                    brief_dicion_valor
                WHERE
                    briefing_id = v_briefing_ant_id;

        ELSE
   -- usa metadados definidos para o tipo de job
            INSERT INTO brief_atributo_valor (
                briefing_id,
                metadado_id,
                valor_atributo
            )
                SELECT
                    v_briefing_id,
                    ab.metadado_id,
                    NULL
                FROM
                    metadado ab
                WHERE
                        ab.tipo_objeto = 'TIPO_JOB'
                    AND ab.objeto_id = v_tipo_job_id
                    AND ab.flag_ativo = 'S'
                    AND grupo = 'BRIEFING';

        END IF;
  --
  ------------------------------------------------------------
  -- tratamento do cronograma
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
   --
            SELECT
                MAX(item_crono_id)
            INTO v_item_crono_id
            FROM
                item_crono
            WHERE
                    cronograma_id = v_cronograma_id
                AND cod_objeto = 'BRIEFING';

        ELSE
   -- verifica se precisa instanciar a atividade de briefing
            cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id, p_empresa_id, v_cronograma_id, 'BRIEFING', 'IME',
                                                v_item_crono_id, p_erro_cod, p_erro_msg);

            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  -- vincula a atividade de briefing ao novo briefing criado
        UPDATE item_crono
        SET
            objeto_id = v_briefing_id
        WHERE
            item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(v_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := v_motivo;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'INCLUIR', v_identif_objeto,
                        v_briefing_id, v_compl_histor, NULL, 'N', NULL,
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
        p_briefing_id := v_briefing_id;
        p_erro_cod := '00000';
        p_erro_msg := 'Operação realizada com sucesso.';
  --
    EXCEPTION
        WHEN v_exception THEN
            ROLLBACK;
        WHEN dup_val_on_index THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse número de '
                          || v_lbl_brief
                          || ' já existe ('
                          || to_char(v_num_briefing)
                          || '). Tente novamente.';

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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Atualização de BRIEFING
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/06/2006  Retirada dos campos que guardavam informacoes da solucao
  --                               Aktuell e do retorno do cliente.
  -- Silvia            28/09/2012  Geracao de tarefa para brieging pronto.
  -- Silvia            14/01/2014  Retirada de data requisicao e inclusao de area e motivo
  -- Silvia            14/05/2015  Metadados de briefing
  -- Silvia            04/01/2016  Novo campo status no lugar do flag_pronto. Retirada da 
  --                               criacao da nova versao (parametros de motivo). Novo 
  --                               campo revisoes.
  -- Silvia            16/08/2017  Validacao de metadado.
  -- Silvia            19/06/2019  Troca do delimitador para ^
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id    IN NUMBER,
        p_empresa_id           IN empresa.empresa_id%TYPE,
        p_briefing_id          IN briefing.briefing_id%TYPE,
        p_requisicao_cliente   IN briefing.requisicao_cliente%TYPE,
        p_revisoes             IN briefing.revisoes%TYPE,
        p_vetor_area_id        IN VARCHAR2,
        p_vetor_atributo_id    IN VARCHAR2,
        p_vetor_atributo_valor IN CLOB,
        p_erro_cod             OUT VARCHAR2,
        p_erro_msg             OUT VARCHAR2
    ) IS

        v_qt                   INTEGER;
        v_exception EXCEPTION;
        v_numero_job           job.numero%TYPE;
        v_status_job           job.status%TYPE;
        v_job_id               job.job_id%TYPE;
        v_budget               job.budget%TYPE;
        v_num_briefing         briefing.numero%TYPE;
        v_status_brief         briefing.status%TYPE;
        v_identif_objeto       historico.identif_objeto%TYPE;
        v_compl_histor         historico.complemento%TYPE;
        v_historico_id         historico.historico_id%TYPE;
        v_delimitador          CHAR(1);
        v_vetor_area_id        VARCHAR2(1000);
        v_area_id              area.area_id%TYPE;
        v_lbl_job              VARCHAR2(100);
        v_lbl_brief            VARCHAR2(100);
        v_flag_budget_obrig    VARCHAR2(10);
        v_vetor_atributo_id    LONG;
        v_vetor_atributo_valor LONG;
        v_metadado_id          metadado.metadado_id%TYPE;
        v_nome_atributo        metadado.nome%TYPE;
        v_tamanho              metadado.tamanho%TYPE;
        v_flag_obrigatorio     metadado.flag_obrigatorio%TYPE;
        v_tipo_dado            tipo_dado.codigo%TYPE;
        v_valor_atributo       LONG;
        v_valor_atributo_sai   LONG;
        v_xml_antes            CLOB;
        v_xml_atual            CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
        v_flag_budget_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BUDGET_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            briefing b,
            job      j
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.job_id,
            j.status,
            b.numero,
            b.status,
            j.budget
        INTO
            v_numero_job,
            v_job_id,
            v_status_job,
            v_num_briefing,
            v_status_brief,
            v_budget
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief NOT IN ( 'PREP', 'REPROV' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_job
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF
            v_flag_budget_obrig = 'S'
            AND nvl(v_budget, 0) = 0
        THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O budget do '
                          || v_lbl_job
                          || ' deve ser informado.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_vetor_atributo_valor) > 32767 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'A quantidade de caracteres dos metadados ultrapassou o limite de 32767.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE briefing
        SET
            requisicao_cliente = p_requisicao_cliente,
            revisoes = p_revisoes
        WHERE
            briefing_id = p_briefing_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de areas
  ------------------------------------------------------------
        DELETE FROM brief_area
        WHERE
            briefing_id = p_briefing_id;
  --
        v_delimitador := '^';
        v_vetor_area_id := p_vetor_area_id;
  --
        WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0 LOOP
            v_area_id := TO_NUMBER ( prox_valor_retornar(v_vetor_area_id, v_delimitador) );
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                area
            WHERE
                    area_id = v_area_id
                AND empresa_id = p_empresa_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Essa área não existe ou não pertence a essa empresa ('
                              || to_char(v_area_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            INSERT INTO brief_area (
                briefing_id,
                area_id
            ) VALUES (
                p_briefing_id,
                v_area_id
            );

        END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de metadados
  ------------------------------------------------------------
        DELETE FROM brief_atributo_valor
        WHERE
            briefing_id = p_briefing_id;
  --
        v_delimitador := '^';
        v_vetor_atributo_id := p_vetor_atributo_id;
        v_vetor_atributo_valor := p_vetor_atributo_valor;
  --
        WHILE nvl(length(rtrim(v_vetor_atributo_id)), 0) > 0 LOOP
            v_metadado_id := TO_NUMBER ( prox_valor_retornar(v_vetor_atributo_id, v_delimitador) );
            v_valor_atributo := prox_valor_retornar(v_vetor_atributo_valor, v_delimitador);
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                metadado
            WHERE
                    metadado_id = v_metadado_id
                AND grupo = 'BRIEFING';
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Metadado inválido ('
                              || to_char(v_metadado_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            SELECT
                ab.nome,
                ab.tamanho,
                ab.flag_obrigatorio,
                td.codigo
            INTO
                v_nome_atributo,
                v_tamanho,
                v_flag_obrigatorio,
                v_tipo_dado
            FROM
                metadado  ab,
                tipo_dado td
            WHERE
                    ab.metadado_id = v_metadado_id
                AND ab.tipo_dado_id = td.tipo_dado_id;
   --
            tipo_dado_pkg.validar(p_usuario_sessao_id, p_empresa_id, v_tipo_dado, v_flag_obrigatorio, 'N',
                                 v_tamanho, v_valor_atributo, v_valor_atributo_sai, p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                p_erro_msg := v_nome_atributo
                              || ': '
                              || p_erro_msg;
                RAISE v_exception;
            END IF;
   --
            INSERT INTO brief_atributo_valor (
                briefing_id,
                metadado_id,
                valor_atributo
            ) VALUES (
                p_briefing_id,
                v_metadado_id,
                TRIM(v_valor_atributo_sai)
            );

        END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'ALTERAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    PROCEDURE dicion_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/11/2016
  -- DESCRICAO: Atualização da matriz do BRIEFING
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_briefing_id             IN briefing.briefing_id%TYPE,
        p_vetor_dicion_emp_id     IN VARCHAR2,
        p_vetor_dicion_emp_val_id IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    ) IS

        v_qt                      INTEGER;
        v_exception EXCEPTION;
        v_numero_job              job.numero%TYPE;
        v_status_job              job.status%TYPE;
        v_job_id                  job.job_id%TYPE;
        v_num_briefing            briefing.numero%TYPE;
        v_status_brief            briefing.status%TYPE;
        v_identif_objeto          historico.identif_objeto%TYPE;
        v_compl_histor            historico.complemento%TYPE;
        v_historico_id            historico.historico_id%TYPE;
        v_descricao               tarefa.descricao%TYPE;
        v_delimitador             CHAR(1);
        v_lbl_job                 VARCHAR2(100);
        v_lbl_brief               VARCHAR2(100);
        v_vetor_dicion_emp_id     LONG;
        v_vetor_dicion_emp_val_id LONG;
        v_dicion_emp_id           dicion_emp.dicion_emp_id%TYPE;
        v_dicion_desc             dicion_emp.descricao%TYPE;
        v_dicion_emp_val_id       dicion_emp_val.dicion_emp_val_id%TYPE;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            briefing b,
            job      j
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.job_id,
            j.status,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_job_id,
            v_status_job,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
  ------------------------------------------------------------
  -- tratamento dos vetores da matriz de classif (dicionario)
  ------------------------------------------------------------
        DELETE FROM brief_dicion_valor
        WHERE
            briefing_id = p_briefing_id;
  --
        v_delimitador := '|';
        v_vetor_dicion_emp_id := p_vetor_dicion_emp_id;
        v_vetor_dicion_emp_val_id := p_vetor_dicion_emp_val_id;
  --
        WHILE nvl(length(rtrim(v_vetor_dicion_emp_id)), 0) > 0 LOOP
            v_dicion_emp_id := TO_NUMBER ( prox_valor_retornar(v_vetor_dicion_emp_id, v_delimitador) );
            v_dicion_emp_val_id := nvl(TO_NUMBER(prox_valor_retornar(v_vetor_dicion_emp_val_id, v_delimitador)), 0);
   --
            SELECT
                MAX(descricao)
            INTO v_dicion_desc
            FROM
                dicion_emp
            WHERE
                dicion_emp_id = v_dicion_emp_id;
   --
            IF v_dicion_desc IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Atributo do dicionário inválido ('
                              || to_char(v_dicion_emp_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            IF v_dicion_emp_val_id = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'O preenchimento de '
                              || v_dicion_desc
                              || ' é obrigatório.';
                RAISE v_exception;
            END IF;
   --
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                dicion_emp_val
            WHERE
                    dicion_emp_val_id = v_dicion_emp_val_id
                AND dicion_emp_id = v_dicion_emp_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Valor de atributo não encontrado ('
                              || to_char(v_dicion_emp_val_id)
                              || ').';
                RAISE v_exception;
            END IF;
   --
            INSERT INTO brief_dicion_valor (
                briefing_id,
                dicion_emp_val_id
            ) VALUES (
                p_briefing_id,
                v_dicion_emp_val_id
            );

        END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := 'Matriz de classificação';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'ALTERAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', NULL,
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
    END dicion_atualizar;
 --
 --
    PROCEDURE dicion_verificar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/11/2016
  -- DESCRICAO: Verificacao do preenchimento da matriz do BRIEFING
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_exception EXCEPTION;
        v_job_id            job.job_id%TYPE;
        v_num_briefing      briefing.numero%TYPE;
        v_lbl_job           VARCHAR2(100);
        v_dicion_emp_id     dicion_emp.dicion_emp_id%TYPE;
        v_dicion_desc       dicion_emp.descricao%TYPE;
        v_dicion_emp_val_id dicion_emp_val.dicion_emp_val_id%TYPE;
  --
        CURSOR c_di IS
        SELECT
            dicion_emp_id,
            descricao
        FROM
            dicion_emp
        WHERE
                grupo = 'MATRIZ_CLAS'
            AND flag_ativo = 'S'
            AND empresa_id = p_empresa_id
        ORDER BY
            ordem;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- pega o briefing mais recente do job
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            briefing
        WHERE
            briefing_id = p_briefing_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse briefing não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.job_id,
            b.numero
        INTO
            v_job_id,
            v_num_briefing
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
  ------------------------------------------------------------
  -- verificacao do preenchimento
  ------------------------------------------------------------
        FOR r_di IN c_di LOOP
   -- verifica se, para esse atributo, existe pelo menos um valor
   -- associado ao briefing.
            SELECT
                COUNT(*)
            INTO v_qt
            FROM
                dicion_emp_val     dv,
                brief_dicion_valor bv
            WHERE
                    dv.dicion_emp_id = r_di.dicion_emp_id
                AND dv.dicion_emp_val_id = bv.dicion_emp_val_id
                AND bv.briefing_id = p_briefing_id;
   --
            IF v_qt = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Matriz do briefing '
                              || to_char(v_num_briefing)
                              || ' incompleta ('
                              || r_di.descricao
                              || ').';

                RAISE v_exception;
            END IF;

        END LOOP;
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
    END dicion_verificar;
 --
 --
    PROCEDURE task_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/08/2006
  -- DESCRICAO: Gera tasks relacionadas a um determinado briefing
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_prioridade        IN task.prioridade%TYPE,
        p_vetor_papel_id    IN LONG,
        p_obs               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_numero_job     job.numero%TYPE;
        v_status_job     job.status%TYPE;
        v_job_id         job.job_id%TYPE;
        v_num_briefing   briefing.numero%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_papel_id       papel.papel_id%TYPE;
        v_delimitador    CHAR(1);
        v_vetor_papel_id LONG;
        v_task_id        task.task_id%TYPE;
        v_tipo_objeto_id task.tipo_objeto_id%TYPE;
        v_usuario        pessoa.apelido%TYPE;
        v_desc_curta     task.desc_curta%TYPE;
        v_desc_detalhada task.desc_detalhada%TYPE;
        v_tipo_task      task.tipo_task%TYPE;
        v_lbl_job        VARCHAR2(100);
        v_lbl_brief      VARCHAR2(100);
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            briefing b,
            job      j
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.job_id,
            j.status,
            b.numero
        INTO
            v_numero_job,
            v_job_id,
            v_status_job,
            v_num_briefing
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
            codigo = 'BRIEFING';
  --
        IF v_tipo_objeto_id IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Não existe tipo de objeto criado para '
                          || v_lbl_brief
                          || '.';
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
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF length(p_obs) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O texto das observações não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_vetor_papel_id) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'É necessário indicar pelo menos um papel como responsável pela task.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        v_tipo_task := 'BRIEF_MSG';
        v_desc_curta := 'Tomar conhecimento do ' || v_lbl_brief;
        v_desc_detalhada := rtrim(v_usuario
                                  || ' solicitou que tome conhecimento do '
                                  || v_lbl_brief
                                  || '. '
                                  || p_obs);
  --
        v_delimitador := ',';
        v_vetor_papel_id := p_vetor_papel_id;
  --
        WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0 LOOP
            v_papel_id := TO_NUMBER ( prox_valor_retornar(v_vetor_papel_id, v_delimitador) );
   --
            task_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', -- flag_commit
             v_job_id, 0, -- milestone_id
                              v_papel_id, v_desc_curta, v_desc_detalhada, p_prioridade, v_tipo_task,
                              v_task_id, -- output
                               p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
   --
   -- vincula o briefing a essa task
            UPDATE task
            SET
                objeto_id = p_briefing_id,
                tipo_objeto_id = v_tipo_objeto_id
            WHERE
                task_id = v_task_id;

        END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := 'Geração de tasks de briefing';
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'ALTERAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', NULL,
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
    END; -- task_gerar
 --
 --
    PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Exclusão de BRIEFING
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/01/2014  Exclusao de historico e areas.
  -- Silvia            14/05/2015  Exclusao de metadados.
  -- Silvia            19/01/2016  Tratamento de cronograma
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_exception EXCEPTION;
        v_numero_job     job.numero%TYPE;
        v_job_id         job.job_id%TYPE;
        v_status_job     job.status%TYPE;
        v_briefing_id    briefing.briefing_id%TYPE;
        v_num_briefing   briefing.numero%TYPE;
        v_status_brief   briefing.status%TYPE;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_cronograma_id  item_crono.cronograma_id%TYPE;
        v_item_crono_id  item_crono.item_crono_id%TYPE;
        v_lbl_job        VARCHAR2(100);
        v_lbl_brief      VARCHAR2(100);
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            briefing b,
            job      j
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.job_id,
            j.status,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_job_id,
            v_status_job,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief NOT IN ( 'PREP', 'REPROV' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
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
            os_evento
        WHERE
                briefing_id = p_briefing_id
            AND ROWNUM = 1;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' tem eventos de Workflow associados.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM brief_area
        WHERE
            briefing_id = p_briefing_id;

        DELETE FROM brief_hist
        WHERE
            briefing_id = p_briefing_id;

        DELETE FROM brief_atributo_valor
        WHERE
            briefing_id = p_briefing_id;

        DELETE FROM briefing
        WHERE
            briefing_id = p_briefing_id;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
        UPDATE item_crono ic
        SET
            objeto_id = NULL
        WHERE
                cod_objeto = 'BRIEFING'
            AND objeto_id = p_briefing_id;
  --
        v_briefing_id := briefing_pkg.ultimo_retornar(v_job_id);
        v_cronograma_id := cronograma_pkg.ultimo_retornar(v_job_id);
  --
        IF nvl(v_cronograma_id, 0) = 0 THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
            cronograma_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', v_job_id, v_cronograma_id,
                                    p_erro_cod, p_erro_msg);

            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
   --
            SELECT
                MAX(item_crono_id)
            INTO v_item_crono_id
            FROM
                item_crono
            WHERE
                    cronograma_id = v_cronograma_id
                AND cod_objeto = 'BRIEFING';

        ELSE
   -- verifica se precisa instanciar a atividade de briefing
            cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id, p_empresa_id, v_cronograma_id, 'BRIEFING', 'IME',
                                                v_item_crono_id, p_erro_cod, p_erro_msg);

            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        END IF;
  --
  -- vincula a atividade de briefing ao briefing anterior (pode ser nulo)
        UPDATE item_crono
        SET
            objeto_id = zvl(v_briefing_id, NULL)
        WHERE
            item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'EXCLUIR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', NULL,
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
    PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Termino de briefing (envia para aprovacao ou aprova automaticamente).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt                  INTEGER;
        v_identif_objeto      historico.identif_objeto%TYPE;
        v_compl_histor        historico.complemento%TYPE;
        v_historico_id        historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_briefing        briefing.numero%TYPE;
        v_status_brief        briefing.status%TYPE;
        v_data_aprov_limite   briefing.data_aprov_limite%TYPE;
        v_numero_job          job.numero%TYPE;
        v_status_job          job.status%TYPE;
        v_job_id              job.job_id%TYPE;
        v_flag_apr_brief_auto tipo_job.flag_apr_brief_auto%TYPE;
        v_lbl_job             VARCHAR2(100);
        v_lbl_brief           VARCHAR2(100);
        v_xml_antes           CLOB;
        v_xml_atual           CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            b.numero,
            b.status,
            t.flag_apr_brief_auto
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_num_briefing,
            v_status_brief,
            v_flag_apr_brief_auto
        FROM
            job      j,
            briefing b,
            tipo_job t
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.tipo_job_id = t.tipo_job_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief NOT IN ( 'PREP', 'REPROV' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id, p_empresa_id, sysdate, 'NUM_HORAS_APROV_BRIEF'
        , 0);
        UPDATE briefing
        SET
            status = 'EMAPRO',
            data_status = sysdate,
            data_aprov_limite = v_data_aprov_limite
        WHERE
            briefing_id = p_briefing_id;
  --
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            p_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            'Término',
            NULL
        );
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'TERMINAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        IF v_flag_apr_brief_auto = 'S' THEN
   -- aprova o briefing automaticamente
            briefing_pkg.aprovar(p_usuario_sessao_id, p_empresa_id, 'N', p_briefing_id, NULL,
                                p_erro_cod, p_erro_msg);
   --
            IF p_erro_cod <> '00000' THEN
                RAISE v_exception;
            END IF;
        ELSE
   -- marca o briefing como tendo transicao de aprovacao (o padrao na hora de 
   -- criar o briefing eh nao.
            UPDATE briefing
            SET
                flag_com_aprov = 'S'
            WHERE
                briefing_id = p_briefing_id;

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
    END terminar;
 --
 --
    PROCEDURE retomar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Retomada de briefing (volta para preparacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_briefing   briefing.numero%TYPE;
        v_status_brief   briefing.status%TYPE;
        v_numero_job     job.numero%TYPE;
        v_status_job     job.status%TYPE;
        v_job_id         job.job_id%TYPE;
        v_lbl_job        VARCHAR2(100);
        v_lbl_brief      VARCHAR2(100);
        v_xml_antes      CLOB;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_C', v_job_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief <> ( 'EMAPRO' ) THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE briefing
        SET
            status = 'PREP',
            data_status = sysdate
        WHERE
            briefing_id = p_briefing_id;
  --
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            p_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            'Retomada',
            NULL
        );
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'RETOMAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    END retomar;
 --
 --
    PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Aprovacao de briefing.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/06/2018  Novo parametro nota_aval
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_nota_aval         IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_briefing   briefing.numero%TYPE;
        v_status_brief   briefing.status%TYPE;
        v_nota_aval      briefing.nota_aval%TYPE;
        v_numero_job     job.numero%TYPE;
        v_status_job     job.status%TYPE;
        v_job_id         job.job_id%TYPE;
        v_lbl_job        VARCHAR2(100);
        v_lbl_brief      VARCHAR2(100);
        v_usa_nota       VARCHAR2(40);
        v_xml_antes      CLOB;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
        v_usa_nota := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_NOTA_AVAL_BRIEFING');
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
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b,
            tipo_job t
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.tipo_job_id = t.tipo_job_id;
  --
        IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
            IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_AP', v_job_id, NULL, p_empresa_id) = 0 THEN
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
        IF v_status_brief <> 'EMAPRO' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
        IF v_usa_nota = 'N' OR p_flag_commit = 'N' THEN
   -- nota de avaliacao desabilitada ou aprovacao automatica
            v_nota_aval := NULL;
        ELSE
            IF TRIM(p_nota_aval) IS NULL THEN
                p_erro_cod := '90000';
                p_erro_msg := 'O preenchimento da nota de avaliação é obrigatório.';
                RAISE v_exception;
            END IF;
   --
            IF inteiro_validar(p_nota_aval) = 0 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Nota de avaliação inválida ('
                              || p_nota_aval
                              || ').';
                RAISE v_exception;
            END IF;
   --
            v_nota_aval := TO_NUMBER ( p_nota_aval );
   --
            IF v_nota_aval NOT BETWEEN 1 AND 5 THEN
                p_erro_cod := '90000';
                p_erro_msg := 'Nota de avaliação inválida ('
                              || p_nota_aval
                              || ').';
                RAISE v_exception;
            END IF;

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE briefing
        SET
            status = 'APROV',
            data_status = sysdate,
            nota_aval = v_nota_aval
        WHERE
            briefing_id = p_briefing_id;
  --
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            p_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            'Aprovação',
            NULL
        );
  --
  -- passa usuario_sessao_id = 0 (para marcar todos os usuarios enderecados)
        job_pkg.nao_lido_marcar(0, p_empresa_id, v_job_id, 'ENDER_TODOS', p_erro_cod,
                               p_erro_msg);
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'APROVAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, NULL, 'N', v_xml_antes,
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
    EXCEPTION
        WHEN v_exception THEN
            ROLLBACK;
        WHEN OTHERS THEN
            p_erro_cod := sqlcode;
            p_erro_msg := substr(sqlerrm
                                 || ' Linha Erro: '
                                 || dbms_utility.format_error_backtrace, 1, 200);

            ROLLBACK;
    END aprovar;
 --
 --
    PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Reprovacao de briefing.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_motivo_reprov     IN VARCHAR2,
        p_compl_reprov      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt             INTEGER;
        v_identif_objeto historico.identif_objeto%TYPE;
        v_compl_histor   historico.complemento%TYPE;
        v_historico_id   historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_briefing   briefing.numero%TYPE;
        v_status_brief   briefing.status%TYPE;
        v_numero_job     job.numero%TYPE;
        v_status_job     job.status%TYPE;
        v_job_id         job.job_id%TYPE;
        v_lbl_job        VARCHAR2(100);
        v_lbl_brief      VARCHAR2(100);
        v_xml_antes      CLOB;
        v_xml_atual      CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_AP', v_job_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief <> 'EMAPRO' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_motivo_reprov) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do motivo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(trim(p_motivo_reprov)) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF length(trim(p_compl_reprov)) > 1000 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE briefing
        SET
            status = 'REPROV',
            data_status = sysdate
        WHERE
            briefing_id = p_briefing_id;
  --
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            p_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            substr('Reprovação: ' || TRIM(p_motivo_reprov),
                   1,
                   100),
            TRIM(p_compl_reprov)
        );
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := trim(p_compl_reprov);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'REPROVAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, trim(p_motivo_reprov), 'N', v_xml_antes,
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
    END reprovar;
 --
 --
    PROCEDURE revisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Revisao de briefing aprovado (arquiva atual e abre novo briefing).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_motivo_rev        IN VARCHAR2,
        p_compl_rev         IN VARCHAR2,
        p_briefing_new_id   OUT briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt              INTEGER;
        v_identif_objeto  historico.identif_objeto%TYPE;
        v_compl_histor    historico.complemento%TYPE;
        v_historico_id    historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_briefing    briefing.numero%TYPE;
        v_status_brief    briefing.status%TYPE;
        v_briefing_new_id briefing.briefing_id%TYPE;
        v_numero_job      job.numero%TYPE;
        v_status_job      job.status%TYPE;
        v_job_id          job.job_id%TYPE;
        v_lbl_job         VARCHAR2(100);
        v_lbl_brief       VARCHAR2(100);
        v_xml_antes       CLOB;
        v_xml_atual       CLOB;
  --
    BEGIN
        v_qt := 0;
        v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
        v_lbl_brief := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
        p_briefing_new_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id
            AND j.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse '
                          || v_lbl_brief
                          || ' não existe.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            j.numero,
            j.status,
            j.job_id,
            b.numero,
            b.status
        INTO
            v_numero_job,
            v_status_job,
            v_job_id,
            v_num_briefing,
            v_status_brief
        FROM
            job      j,
            briefing b
        WHERE
                b.briefing_id = p_briefing_id
            AND b.job_id = j.job_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'BRIEF_RV', v_job_id, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
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
        IF v_status_brief <> 'APROV' THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O status do '
                          || v_lbl_brief
                          || ' não permite essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_motivo_rev) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do motivo é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(trim(p_motivo_rev)) > 100 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
            RAISE v_exception;
        END IF;
  --
        IF length(trim(p_compl_rev)) > 1000 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        UPDATE briefing
        SET
            status = 'ARQUI',
            data_status = sysdate
        WHERE
            briefing_id = p_briefing_id;
  --
        INSERT INTO brief_hist (
            brief_hist_id,
            briefing_id,
            usuario_id,
            data,
            motivo,
            compl_motivo
        ) VALUES (
            seq_brief_hist.NEXTVAL,
            p_briefing_id,
            p_usuario_sessao_id,
            sysdate,
            substr('Revisão: ' || TRIM(p_motivo_rev),
                   1,
                   100),
            TRIM(p_compl_rev)
        );
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
        briefing_pkg.xml_gerar(p_briefing_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := to_char(v_numero_job)
                            || '/'
                            || to_char(v_num_briefing);
        v_compl_histor := trim(p_compl_rev);
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'BRIEFING', 'REVISAR', v_identif_objeto,
                        p_briefing_id, v_compl_histor, trim(p_motivo_rev), 'N', v_xml_antes,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- criacao da nova versao
  ------------------------------------------------------------
        briefing_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', v_job_id, NULL,
                              v_briefing_new_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        COMMIT;
        p_briefing_new_id := v_briefing_new_id;
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
    END revisar;
 --
 --
    PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/06/2018
  -- DESCRICAO: Subrotina que gera o xml do briefing para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_briefing_id IN briefing.briefing_id%TYPE,
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
        CURSOR c_ar IS
        SELECT
            ar.nome AS area
        FROM
            brief_area ba,
            area       ar
        WHERE
                ba.briefing_id = p_briefing_id
            AND ba.area_id = ar.area_id
        ORDER BY
            ar.nome;
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
                "briefing_id",
                      to_char(br.briefing_id)
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
                "status_job",
                      jo.status
            ),
                      XMLELEMENT(
                "numero_briefing",
                      br.numero
            ),
                      XMLELEMENT(
                "status_briefing",
                      br.status
            ),
                      XMLELEMENT(
                "autor",
                      pu.apelido
            ),
                      XMLELEMENT(
                "data_requisicao",
                      data_hora_mostrar(br.data_requisicao)
            ),
                      XMLELEMENT(
                "com_aprovacao",
                      br.flag_com_aprov
            ),
                      XMLELEMENT(
                "data_aprov_limite",
                      data_hora_mostrar(br.data_aprov_limite)
            ),
                      XMLELEMENT(
                "nota_avaliacao",
                      to_char(br.nota_aval)
            ))
        INTO v_xml
        FROM
            briefing br,
            job      jo,
            pessoa   pu
        WHERE
                br.briefing_id = p_briefing_id
            AND br.job_id = jo.job_id
            AND br.usuario_id = pu.usuario_id (+);
  --
  --
  ------------------------------------------------------------
  -- monta AREAS
  ------------------------------------------------------------
        v_xml_aux1 := NULL;
        FOR r_ar IN c_ar LOOP
            SELECT
                xmlconcat(XMLELEMENT(
                    "area",
                          r_ar.area
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
                "areas",
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
  -- junta tudo debaixo de "briefing"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "briefing",
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
    FUNCTION ultimo_retornar (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: retorna o id do briefing mais recente do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
        p_job_id IN job.job_id%TYPE
    ) RETURN INTEGER AS
        v_qt          INTEGER;
        v_briefing_id briefing.briefing_id%TYPE;
  --
    BEGIN
        v_briefing_id := NULL;
  --
        SELECT
            MAX(briefing_id)
        INTO v_briefing_id
        FROM
            briefing
        WHERE
            job_id = p_job_id;
  --
        RETURN v_briefing_id;
  --
    EXCEPTION
        WHEN OTHERS THEN
            v_briefing_id := NULL;
            RETURN v_briefing_id;
    END ultimo_retornar;
 --
--
END; -- BRIEFING_PKG



/
