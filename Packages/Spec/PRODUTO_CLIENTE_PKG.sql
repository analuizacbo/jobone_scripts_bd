--------------------------------------------------------
--  DDL for Package PRODUTO_CLIENTE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PRODUTO_CLIENTE_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_flag_commit        IN VARCHAR2,
        p_pessoa_id          IN produto_cliente.pessoa_id%TYPE,
        p_nome               IN produto_cliente.nome%TYPE,
        p_produto_cliente_id OUT produto_cliente.produto_cliente_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_produto_cliente_id IN produto_cliente.produto_cliente_id%TYPE,
        p_nome               IN produto_cliente.nome%TYPE,
        p_flag_ativo         IN produto_cliente.flag_ativo%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_produto_cliente_id IN produto_cliente.produto_cliente_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- PRODUTO_CLIENTE_PKG



/
