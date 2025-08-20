--------------------------------------------------------
--  DDL for Package GRUPO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GRUPO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN grupo.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_id          IN grupo.grupo_id%TYPE,
        p_nome              IN grupo.nome%TYPE,
        p_flag_agrupa_cnpj  IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_id          IN grupo.grupo_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_id          IN grupo.grupo_id%TYPE,
        p_pessoa_id         IN pessoa.pessoa_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_id          IN grupo.grupo_id%TYPE,
        p_pessoa_id         IN pessoa.pessoa_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_grupo_id IN grupo.grupo_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
    FUNCTION tem_regra_ender_verificar (
        p_grupo_id IN grupo.grupo_id%TYPE
    ) RETURN INTEGER;
 --
END; -- GRUPO_PKG



/
