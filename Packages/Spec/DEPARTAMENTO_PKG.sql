--------------------------------------------------------
--  DDL for Package DEPARTAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "DEPARTAMENTO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN departamento.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_departamento_id   IN departamento.departamento_id%TYPE,
        p_nome              IN departamento.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_departamento_id   IN departamento.departamento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_departamento_id IN departamento.departamento_id%TYPE,
        p_xml             OUT CLOB,
        p_erro_cod        OUT VARCHAR2,
        p_erro_msg        OUT VARCHAR2
    );
 --
END; -- DEPARTAMENTO_PKG



/
