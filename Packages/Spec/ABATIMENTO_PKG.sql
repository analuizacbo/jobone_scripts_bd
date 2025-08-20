--------------------------------------------------------
--  DDL for Package ABATIMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ABATIMENTO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_carta_acordo_id   IN abatimento.carta_acordo_id%TYPE,
        p_item_id           IN item.item_id%TYPE,
        p_valor_abat        IN VARCHAR2,
        p_flag_debito_cli   IN abatimento.flag_debito_cli%TYPE,
        p_justificativa     IN VARCHAR2,
        p_abatimento_id     OUT abatimento.abatimento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_abatimento_id     IN abatimento.abatimento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE auto_abater (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_sobra_id          IN sobra.sobra_id%TYPE,
        p_abatimento_id     OUT abatimento.abatimento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_abatimento_id IN abatimento.abatimento_id%TYPE,
        p_xml           OUT CLOB,
        p_erro_cod      OUT VARCHAR2,
        p_erro_msg      OUT VARCHAR2
    );
 --
    FUNCTION item_id_retornar (
        p_abatimento_id IN abatimento.abatimento_id%TYPE
    ) RETURN NUMBER;
 --
END; -- ABATIMENTO_PKG



/
