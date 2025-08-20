--------------------------------------------------------
--  DDL for Package NATUREZA_ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "NATUREZA_ITEM_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id          IN NUMBER,
        p_empresa_id                 IN empresa.empresa_id%TYPE,
        p_nome                       IN VARCHAR2,
        p_ordem                      IN VARCHAR2,
        p_codigo                     IN VARCHAR2,
        p_tipo                       IN VARCHAR2,
        p_mod_calculo                IN VARCHAR2,
        p_valor_padrao               IN VARCHAR2,
        p_flag_inc_a                 IN VARCHAR2,
        p_flag_inc_b                 IN VARCHAR2,
        p_flag_inc_c                 IN VARCHAR2,
        p_flag_vinc_ck_a             IN VARCHAR2,
        p_vetor_natureza_item_inc_id IN VARCHAR2,
        p_erro_cod                   OUT VARCHAR2,
        p_erro_msg                   OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id          IN NUMBER,
        p_empresa_id                 IN empresa.empresa_id%TYPE,
        p_natureza_item_id           IN natureza_item.natureza_item_id%TYPE,
        p_nome                       IN VARCHAR2,
        p_ordem                      IN VARCHAR2,
        p_tipo                       IN VARCHAR2,
        p_flag_ativo                 IN VARCHAR2,
        p_mod_calculo                IN VARCHAR2,
        p_valor_padrao               IN VARCHAR2,
        p_flag_inc_a                 IN VARCHAR2,
        p_flag_inc_b                 IN VARCHAR2,
        p_flag_inc_c                 IN VARCHAR2,
        p_flag_vinc_ck_a             IN VARCHAR2,
        p_vetor_natureza_item_inc_id IN VARCHAR2,
        p_erro_cod                   OUT VARCHAR2,
        p_erro_msg                   OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_natureza_item_id  IN natureza_item.natureza_item_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_natureza_item_id IN natureza_item.natureza_item_id%TYPE,
        p_xml              OUT CLOB,
        p_erro_cod         OUT VARCHAR2,
        p_erro_msg         OUT VARCHAR2
    );
 --
    FUNCTION valor_padrao_retornar (
        p_cod_objeto    IN VARCHAR2,
        p_objeto_id     IN NUMBER,
        p_natureza_item IN VARCHAR2
    ) RETURN NUMBER;
 --
END; -- NATUREZA_ITEM_PKG



/
