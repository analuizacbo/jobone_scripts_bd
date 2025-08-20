--------------------------------------------------------
--  DDL for Package SETOR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SETOR_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_setor_id          OUT setor.setor_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_setor_id          IN setor.setor_id%TYPE,
        p_nome              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_setor_id          IN setor.setor_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_setor_id IN setor.setor_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
END; -- SETOR_PKG



/
