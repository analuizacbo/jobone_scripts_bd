--------------------------------------------------------
--  DDL for Package Body ABATIMENTO_CTR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ABATIMENTO_CTR_PKG" IS
 --
    PROCEDURE adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: Inclusão de ABATIMENTO de contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
        p_valor_abat          IN VARCHAR2,
        p_flag_debito_cli     IN abatimento.flag_debito_cli%TYPE,
        p_justificativa       IN VARCHAR2,
        p_abatimento_ctr_id   OUT abatimento_ctr.abatimento_ctr_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    ) IS

        v_qt                INTEGER;
        v_identif_objeto    historico.identif_objeto%TYPE;
        v_compl_histor      historico.complemento%TYPE;
        v_historico_id      historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_contrato      contrato.numero%TYPE;
        v_nome_contrato     contrato.nome%TYPE;
        v_contrato_id       contrato.contrato_id%TYPE;
        v_cliente_id        contrato.contratante_id%TYPE;
        v_abatimento_ctr_id abatimento_ctr.abatimento_ctr_id%TYPE;
        v_valor_abat        abatimento_ctr.valor_abat%TYPE;
        v_num_parcela       parcela_contrato.num_parcela%TYPE;
        v_operador          lancamento.operador%TYPE;
        v_descricao         lancamento.descricao%TYPE;
        v_valor_pend        NUMBER;
        v_xml_atual         CLOB;
  --
    BEGIN
        v_qt := 0;
        p_abatimento_ctr_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            parcela_contrato pa,
            contrato         ct
        WHERE
                pa.parcela_contrato_id = p_parcela_contrato_id
            AND pa.contrato_id = ct.contrato_id
            AND ct.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa parcela não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;
  --
        SELECT
            ct.numero,
            ct.contratante_id,
            ct.nome,
            ct.contrato_id,
            pa.num_parcela
        INTO
            v_num_contrato,
            v_cliente_id,
            v_nome_contrato,
            v_contrato_id,
            v_num_parcela
        FROM
            parcela_contrato pa,
            contrato         ct
        WHERE
                pa.parcela_contrato_id = p_parcela_contrato_id
            AND pa.contrato_id = ct.contrato_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_FATUR_C', NULL, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
        IF TRIM(p_valor_abat) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento do valor a abater é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF moeda_validar(p_valor_abat) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Valor a abater inválido.';
            RAISE v_exception;
        END IF;
  --
        v_valor_abat := nvl(moeda_converter(p_valor_abat), 0);
  --
        IF v_valor_abat <= 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Valor a abater inválido.';
            RAISE v_exception;
        END IF;
  --
        IF flag_validar(p_flag_debito_cli) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Flag debitar do cliente inválido.';
            RAISE v_exception;
        END IF;
  --
        IF rtrim(p_justificativa) IS NULL THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O preenchimento da justificativa é obrigatório.';
            RAISE v_exception;
        END IF;
  --
        IF length(p_justificativa) > 500 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'O texto da justificativa não pode ter mais que 500 caracteres.';
            RAISE v_exception;
        END IF;
  --
        v_valor_pend := contrato_pkg.valor_parcela_retornar(p_parcela_contrato_id, 'AFATURAR');
  --
        IF v_valor_abat > v_valor_pend THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Essa parcela não tem saldo suficiente para esse abatimento (Parcela: '
                          || to_char(v_num_parcela)
                          || ', Saldo: '
                          || moeda_mostrar(v_valor_pend, 'S')
                          || ').';

            RAISE v_exception;
        END IF;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            abatimento_ctr
        WHERE
            parcela_contrato_id = p_parcela_contrato_id;
  --
        IF v_qt > 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Já existe abatimento para essa parcela.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        SELECT
            seq_abatimento.NEXTVAL
        INTO v_abatimento_ctr_id
        FROM
            dual;
  --
        INSERT INTO abatimento_ctr (
            abatimento_ctr_id,
            parcela_contrato_id,
            usuario_resp_id,
            data_entrada,
            flag_debito_cli,
            justificativa,
            valor_abat
        ) VALUES (
            v_abatimento_ctr_id,
            p_parcela_contrato_id,
            p_usuario_sessao_id,
            sysdate,
            p_flag_debito_cli,
            TRIM(p_justificativa),
            v_valor_abat
        );
  --
  ------------------------------------------------------------
  -- debito para o cliente
  ------------------------------------------------------------
        IF p_flag_debito_cli = 'S' THEN
            SELECT
                MAX(apelido)
            INTO v_operador
            FROM
                pessoa
            WHERE
                usuario_id = p_usuario_sessao_id;
   --
            v_descricao := 'Abatimento, Contrato '
                           || to_char(v_num_contrato)
                           || ' - '
                           || v_nome_contrato
                           || ', Parcela '
                           || to_char(v_num_parcela);
   --
            INSERT INTO lancamento (
                lancamento_id,
                pessoa_id,
                data_lancam,
                descricao,
                valor_lancam,
                tipo_mov,
                operador,
                justificativa
            ) VALUES (
                seq_lancamento.NEXTVAL,
                v_cliente_id,
                sysdate,
                v_descricao,
                v_valor_abat,
                'S',
                v_operador,
                p_justificativa
            );

        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        abatimento_ctr_pkg.xml_gerar(v_abatimento_ctr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := 'Contrato: '
                            || to_char(v_num_contrato)
                            || '/'
                            || to_char(v_num_parcela)
                            || ' Valor: '
                            || moeda_mostrar(v_valor_abat, 'S');
  --
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'ABATIMENTO_CTR', 'INCLUIR', v_identif_objeto,
                        v_abatimento_ctr_id, v_compl_histor, NULL, 'N', NULL,
                        v_xml_atual, v_historico_id, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
        COMMIT;
  --
        p_abatimento_ctr_id := v_abatimento_ctr_id;
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: Exclusão de ABATIMENTO de contrato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_abatimento_ctr_id IN abatimento_ctr.abatimento_ctr_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt              INTEGER;
        v_identif_objeto  historico.identif_objeto%TYPE;
        v_compl_histor    historico.complemento%TYPE;
        v_historico_id    historico.historico_id%TYPE;
        v_exception EXCEPTION;
        v_num_contrato    contrato.numero%TYPE;
        v_nome_contrato   contrato.nome%TYPE;
        v_contrato_id     contrato.contrato_id%TYPE;
        v_cliente_id      contrato.contratante_id%TYPE;
        v_valor_abat      abatimento_ctr.valor_abat%TYPE;
        v_flag_debito_cli abatimento_ctr.flag_debito_cli%TYPE;
        v_num_parcela     parcela_contrato.num_parcela%TYPE;
        v_operador        lancamento.operador%TYPE;
        v_descricao       lancamento.descricao%TYPE;
        v_xml_atual       CLOB;
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
            abatimento_ctr   ab,
            parcela_contrato pa,
            contrato         ct
        WHERE
                ab.abatimento_ctr_id = p_abatimento_ctr_id
            AND ab.parcela_contrato_id = pa.parcela_contrato_id
            AND pa.contrato_id = ct.contrato_id
            AND ct.empresa_id = p_empresa_id;
  --
        IF v_qt = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Esse abatimento não existe ou não pertence a essa empresa.';
            RAISE v_exception;
        END IF;

        SELECT
            ab.valor_abat,
            ab.flag_debito_cli,
            ct.numero,
            ct.contratante_id,
            ct.nome,
            ct.contrato_id,
            pa.num_parcela
        INTO
            v_valor_abat,
            v_flag_debito_cli,
            v_num_contrato,
            v_cliente_id,
            v_nome_contrato,
            v_contrato_id,
            v_num_parcela
        FROM
            abatimento_ctr   ab,
            parcela_contrato pa,
            contrato         ct
        WHERE
                ab.abatimento_ctr_id = p_abatimento_ctr_id
            AND ab.parcela_contrato_id = pa.parcela_contrato_id
            AND pa.contrato_id = ct.contrato_id;
  --
        IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONTRATO_FATUR_C', NULL, NULL, p_empresa_id) = 0 THEN
            p_erro_cod := '90000';
            p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
        abatimento_ctr_pkg.xml_gerar(p_abatimento_ctr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
        IF p_erro_cod <> '00000' THEN
            RAISE v_exception;
        END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
        DELETE FROM abatimento_ctr
        WHERE
            abatimento_ctr_id = p_abatimento_ctr_id;
  --
  ------------------------------------------------------------
  -- estorno do debito para o cliente
  ------------------------------------------------------------
        IF v_flag_debito_cli = 'S' THEN
            SELECT
                apelido
            INTO v_operador
            FROM
                pessoa
            WHERE
                usuario_id = p_usuario_sessao_id;
   --
            v_descricao := 'Contrato '
                           || to_char(v_num_contrato)
                           || ' - '
                           || v_nome_contrato
                           || ', Parcela '
                           || to_char(v_num_parcela);
   --
            INSERT INTO lancamento (
                lancamento_id,
                pessoa_id,
                data_lancam,
                descricao,
                valor_lancam,
                tipo_mov,
                operador,
                justificativa
            ) VALUES (
                seq_lancamento.NEXTVAL,
                v_cliente_id,
                sysdate,
                v_descricao,
                v_valor_abat,
                'E',
                v_operador,
                'Estorno (resultante de exclusão de abatimento)'
            );

        END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
        v_identif_objeto := 'Contrato: '
                            || to_char(v_num_contrato)
                            || '/'
                            || to_char(v_num_parcela)
                            || ' Valor: '
                            || moeda_mostrar(v_valor_abat, 'S');
  --
        v_compl_histor := NULL;
  --
        evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'ABATIMENTO_CTR', 'EXCLUIR', v_identif_objeto,
                        p_abatimento_ctr_id, v_compl_histor, NULL, 'N', NULL,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/09/2018
  -- DESCRICAO: Subrotina que gera o xml de abatimento de contrato para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_abatimento_ctr_id IN abatimento_ctr.abatimento_ctr_id%TYPE,
        p_xml               OUT CLOB,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    ) IS

        v_qt        INTEGER;
        v_exception EXCEPTION;
        v_xml       XMLTYPE;
        v_xml_aux1  XMLTYPE;
        v_xml_aux99 XMLTYPE;
        v_xml_doc   VARCHAR2(100);
        v_xml_atual CLOB;
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
                "abatimento_ctr_id",
                      ab.abatimento_ctr_id
            ),
                      XMLELEMENT(
                "data_evento",
                      data_hora_mostrar(sysdate)
            ),
                      XMLELEMENT(
                "cliente",
                      pc.apelido
            ),
                      XMLELEMENT(
                "numero_contrato",
                      ct.numero
            ),
                      XMLELEMENT(
                "numero_parcela",
                      pa.num_parcela
            ),
                      XMLELEMENT(
                "responsavel",
                      pe.apelido
            ),
                      XMLELEMENT(
                "data_entrada",
                      data_mostrar(ab.data_entrada)
            ),
                      XMLELEMENT(
                "valor_abatimento",
                      numero_mostrar(ab.valor_abat, 2, 'N')
            ),
                      XMLELEMENT(
                "debito_cliente",
                      ab.flag_debito_cli
            ))
        INTO v_xml
        FROM
            abatimento_ctr   ab,
            parcela_contrato pa,
            contrato         ct,
            pessoa           pe,
            pessoa           pc
        WHERE
                ab.abatimento_ctr_id = p_abatimento_ctr_id
            AND ab.parcela_contrato_id = pa.parcela_contrato_id
            AND pa.contrato_id = ct.contrato_id
            AND ct.contratante_id = pc.pessoa_id
            AND ab.usuario_resp_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "abatimento_ctr"
  ------------------------------------------------------------
        SELECT
            XMLAGG(XMLELEMENT(
                "abatimento_ctr",
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
END; -- ABATIMENTO_CTR_PKG



/
