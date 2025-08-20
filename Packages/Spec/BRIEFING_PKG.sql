--------------------------------------------------------
--  DDL for Package BRIEFING_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "BRIEFING_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN briefing.job_id%TYPE,
        p_vetor_area_id     IN VARCHAR2,
        p_briefing_id       OUT briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id    IN NUMBER,
        p_empresa_id           IN empresa.empresa_id%TYPE,
        p_briefing_id          IN briefing.briefing_id%TYPE,
        p_requisicao_cliente   IN briefing.requisicao_cliente%TYPE,
        p_revisoes             IN briefing.revisoes%TYPE,
        p_vetor_area_id        IN VARCHAR2,
        p_vetor_atributo_id    IN VARCHAR2,
        p_vetor_atributo_valor IN CLOB,
        p_erro_cod             OUT VARCHAR2,
        p_erro_msg             OUT VARCHAR2
    );
 --
    PROCEDURE dicion_atualizar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_briefing_id             IN briefing.briefing_id%TYPE,
        p_vetor_dicion_emp_id     IN VARCHAR2,
        p_vetor_dicion_emp_val_id IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
    PROCEDURE dicion_verificar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE task_gerar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_prioridade        IN task.prioridade%TYPE,
        p_vetor_papel_id    IN LONG,
        p_obs               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE terminar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE retomar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE aprovar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_nota_aval         IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE reprovar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_motivo_reprov     IN VARCHAR2,
        p_compl_reprov      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE revisar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_briefing_id       IN briefing.briefing_id%TYPE,
        p_motivo_rev        IN VARCHAR2,
        p_compl_rev         IN VARCHAR2,
        p_briefing_new_id   OUT briefing.briefing_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_briefing_id IN briefing.briefing_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
    FUNCTION ultimo_retornar (
        p_job_id IN job.job_id%TYPE
    ) RETURN INTEGER;
 --
END; -- BRIEFING_PKG



/
