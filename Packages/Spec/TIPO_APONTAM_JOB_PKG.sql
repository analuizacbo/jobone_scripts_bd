--------------------------------------------------------
--  DDL for Package TIPO_APONTAM_JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_APONTAM_JOB_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_nome                IN tipo_apontam_job.nome%TYPE,
        p_flag_ativo          IN VARCHAR2,
        p_tipo_apontam_job_id OUT tipo_apontam_job.tipo_apontam_job_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_tipo_apontam_job_id IN tipo_apontam_job.tipo_apontam_job_id%TYPE,
        p_nome                IN tipo_apontam_job.nome%TYPE,
        p_flag_ativo          IN VARCHAR2,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_tipo_apontam_job_id IN tipo_apontam_job.tipo_apontam_job_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_apontam_job_id IN tipo_apontam_job.tipo_apontam_job_id%TYPE,
        p_xml                 OUT CLOB,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );

END; -- TIPO_APONTAM_JOB_PKG



/
