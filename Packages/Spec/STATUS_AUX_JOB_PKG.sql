--------------------------------------------------------
--  DDL for Package STATUS_AUX_JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "STATUS_AUX_JOB_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_cod_status_pai    IN status_aux_job.cod_status_pai%TYPE,
        p_nome              IN status_aux_job.nome%TYPE,
        p_ordem             IN VARCHAR2,
        p_flag_padrao       IN VARCHAR2,
        p_status_aux_job_id OUT status_aux_job.status_aux_job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_status_aux_job_id IN status_aux_job.status_aux_job_id%TYPE,
        p_nome              IN status_aux_job.nome%TYPE,
        p_ordem             IN VARCHAR2,
        p_flag_padrao       IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_status_aux_job_id IN status_aux_job.status_aux_job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- STTAUS_AUX_JOB_PKG



/
