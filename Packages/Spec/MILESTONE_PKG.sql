--------------------------------------------------------
--  DDL for Package MILESTONE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "MILESTONE_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_papel_resp_id           IN milestone.papel_resp_id%TYPE,
        p_job_id                  IN milestone.job_id%TYPE,
        p_vetor_tipo_milestone_id IN LONG,
        p_data_milestone          IN VARCHAR2,
        p_hora_ini                IN milestone.hora_ini%TYPE,
        p_hora_fim                IN milestone.hora_fim%TYPE,
        p_descricao               IN milestone.descricao%TYPE,
        p_vetor_usuario_id        IN VARCHAR2,
        p_milestone_id            OUT milestone.milestone_id%TYPE,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_milestone_id            IN milestone.milestone_id%TYPE,
        p_papel_resp_id           IN milestone.papel_resp_id%TYPE,
        p_vetor_tipo_milestone_id IN LONG,
        p_data_milestone          IN VARCHAR2,
        p_hora_ini                IN milestone.hora_ini%TYPE,
        p_hora_fim                IN milestone.hora_fim%TYPE,
        p_descricao               IN milestone.descricao%TYPE,
        p_vetor_usuario_id        IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
    PROCEDURE atualizar_data (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_milestone_id      IN milestone.milestone_id%TYPE,
        p_data_milestone    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_milestone_id      IN milestone.milestone_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE fechar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_milestone_id      IN milestone.milestone_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE reabrir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_milestone_id      IN milestone.milestone_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION atrasado_verificar (
        p_milestone_id IN milestone.milestone_id%TYPE
    ) RETURN INTEGER;
 --
    FUNCTION data_evento_retornar (
        p_empresa_id IN milestone.empresa_id%TYPE,
        p_usuario_id IN usuario.usuario_id%TYPE,
        p_data_refer IN DATE,
        p_sentido    IN VARCHAR2
    ) RETURN DATE;
 --
END; -- MILESTONE_PKG



/
