--------------------------------------------------------
--  DDL for Package ITEM_DECUP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ITEM_DECUP_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_id           IN item_decup.item_id%TYPE,
        p_fornecedor_id     IN item_decup.fornecedor_id%TYPE,
        p_custo_fornec      IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_item_decup_id     OUT item_decup.item_decup_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_decup_id     IN item_decup.item_decup_id%TYPE,
        p_fornecedor_id     IN item_decup.fornecedor_id%TYPE,
        p_custo_fornec      IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_decup_id     IN item_decup.item_decup_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE mover (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_decup_id     IN item_decup.item_decup_id%TYPE,
        p_direcao           IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- ITEM_DECUP_PKG



/
