--------------------------------------------------------
--  DDL for Package JOB_HORAS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "JOB_HORAS_PKG" IS
 --
    PROCEDURE horas_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN job.empresa_id%TYPE,
        p_job_id            IN job_horas.job_id%TYPE,
        p_tipo_formulario   IN VARCHAR2,
        p_usuario_id        IN job_horas.usuario_id%TYPE,
        p_cargo_id          IN job_horas.cargo_id%TYPE,
        p_nivel             IN job_horas.nivel%TYPE,
        p_horas_planej      IN VARCHAR2,
        p_venda_hora_rev    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE horas_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN job.empresa_id%TYPE,
        p_job_horas_id       IN job_horas.job_horas_id%TYPE,
        p_horas_planej       IN VARCHAR2,
        p_venda_fator_ajuste IN VARCHAR2,
        p_venda_hora_rev     IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE horas_ajustar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN job.empresa_id%TYPE,
        p_job_id             IN job.job_id%TYPE,
        p_venda_fator_ajuste IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE horas_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN job.empresa_id%TYPE,
        p_job_horas_id      IN job_horas.job_horas_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE terminar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE retomar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE aprovar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN job.job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE reprovar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_motivo_reprov     IN VARCHAR2,
        p_compl_reprov      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE revisar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_motivo_rev        IN VARCHAR2,
        p_compl_rev         IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
--
END; -- JOB_HORAS_PKG



/
