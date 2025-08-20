--------------------------------------------------------
--  DDL for Package IT_PORTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_PORTO_PKG" IS
 --
    PROCEDURE job_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_job_id             IN job.job_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE ordem_servico_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE comentario_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_comentario_id      IN comentario.comentario_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE porto_executar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_objeto         IN VARCHAR2,
        p_cod_acao           IN VARCHAR2,
        p_objeto_id          IN VARCHAR2,
        p_xml_in             IN CLOB,
        p_xml_out            OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- it_porto_pkg



/
