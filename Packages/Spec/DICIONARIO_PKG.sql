--------------------------------------------------------
--  DDL for Package DICIONARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "DICIONARIO_PKG" IS
 --
    PROCEDURE adicionar (
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
    );
 --
    PROCEDURE atualizar (
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
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_codigo            IN VARCHAR2,
        p_tipo              IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- DICION_EMP_PKG



/
