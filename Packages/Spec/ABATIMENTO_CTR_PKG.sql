--------------------------------------------------------
--  DDL for Package ABATIMENTO_CTR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ABATIMENTO_CTR_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
        p_valor_abat          IN VARCHAR2,
        p_flag_debito_cli     IN abatimento.flag_debito_cli%TYPE,
        p_justificativa       IN VARCHAR2,
        p_abatimento_ctr_id   OUT abatimento_ctr.abatimento_ctr_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_abatimento_ctr_id IN abatimento_ctr.abatimento_ctr_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_abatimento_ctr_id IN abatimento_ctr.abatimento_ctr_id%TYPE,
        p_xml               OUT CLOB,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- ABATIMENTO_CTR_PKG



/
