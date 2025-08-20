--------------------------------------------------------
--  DDL for Package PESQUISA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PESQUISA_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN pesquisa.nome%TYPE,
        p_arquivo           IN VARCHAR2,
        p_url               IN VARCHAR2,
        p_flag_publico      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_pesquisa_id       IN pesquisa.pesquisa_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- PESQUISA_PKG



/
