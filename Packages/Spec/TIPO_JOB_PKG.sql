--------------------------------------------------------
--  DDL for Package TIPO_JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_JOB_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_codigo                  IN tipo_job.codigo%TYPE,
        p_nome                    IN tipo_job.nome%TYPE,
        p_cod_ext_tipo_job        IN tipo_job.cod_ext_tipo_job%TYPE,
        p_modelo_briefing         IN tipo_job.modelo_briefing%TYPE,
        p_flag_padrao             IN VARCHAR2,
        p_complex_job_pdr         IN VARCHAR2,
        p_flag_alt_complex        IN VARCHAR2,
        p_flag_alt_tipo_est       IN VARCHAR2,
        p_flag_tem_camp           IN VARCHAR2,
        p_flag_camp_obr           IN VARCHAR2,
        p_flag_pode_qq_serv       IN VARCHAR2,
        p_flag_pode_os            IN VARCHAR2,
        p_flag_pode_tarefa        IN VARCHAR2,
        p_estrat_job              IN VARCHAR2,
        p_flag_usa_per_job        IN VARCHAR2,
        p_flag_usa_data_cli       IN VARCHAR2,
        p_flag_obriga_data_cli    IN VARCHAR2,
        p_flag_usa_data_golive    IN VARCHAR2,
        p_flag_obr_data_golive    IN VARCHAR2,
        p_flag_apr_brief_auto     IN VARCHAR2,
        p_flag_apr_crono_auto     IN VARCHAR2,
        p_flag_apr_horas_auto     IN VARCHAR2,
        p_flag_apr_orcam_auto     IN VARCHAR2,
        p_flag_cria_crono_auto    IN VARCHAR2,
        p_flag_usa_crono_cria_job IN VARCHAR2,
        p_flag_obr_crono_cria_job IN VARCHAR2,
        p_flag_usa_data_cria_job  IN VARCHAR2,
        p_flag_usa_matriz         IN VARCHAR2,
        p_flag_ender_todos        IN VARCHAR2,
        p_flag_topo_apont         IN VARCHAR2,
        p_tipo_job_id             OUT tipo_job.tipo_job_id%TYPE,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_tipo_job_id             IN tipo_job.tipo_job_id%TYPE,
        p_codigo                  IN tipo_job.codigo%TYPE,
        p_nome                    IN tipo_job.nome%TYPE,
        p_cod_ext_tipo_job        IN tipo_job.cod_ext_tipo_job%TYPE,
        p_modelo_briefing         IN tipo_job.modelo_briefing%TYPE,
        p_flag_ativo              IN VARCHAR2,
        p_flag_padrao             IN VARCHAR2,
        p_complex_job_pdr         IN VARCHAR2,
        p_flag_alt_complex        IN VARCHAR2,
        p_flag_alt_tipo_est       IN VARCHAR2,
        p_flag_tem_camp           IN VARCHAR2,
        p_flag_camp_obr           IN VARCHAR2,
        p_flag_pode_qq_serv       IN VARCHAR2,
        p_flag_pode_os            IN VARCHAR2,
        p_flag_pode_tarefa        IN VARCHAR2,
        p_estrat_job              IN VARCHAR2,
        p_flag_usa_per_job        IN VARCHAR2,
        p_flag_usa_data_cli       IN VARCHAR2,
        p_flag_obriga_data_cli    IN VARCHAR2,
        p_flag_usa_data_golive    IN VARCHAR2,
        p_flag_obr_data_golive    IN VARCHAR2,
        p_flag_apr_brief_auto     IN VARCHAR2,
        p_flag_apr_crono_auto     IN VARCHAR2,
        p_flag_apr_horas_auto     IN VARCHAR2,
        p_flag_apr_orcam_auto     IN VARCHAR2,
        p_flag_cria_crono_auto    IN VARCHAR2,
        p_flag_usa_crono_cria_job IN VARCHAR2,
        p_flag_obr_crono_cria_job IN VARCHAR2,
        p_flag_usa_data_cria_job  IN VARCHAR2,
        p_flag_usa_matriz         IN VARCHAR2,
        p_flag_ender_todos        IN VARCHAR2,
        p_flag_topo_apont         IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE enderecar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN tipo_job.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_area_id           IN papel.area_id%TYPE,
        p_vetor_usuarios    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE papel_priv_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN tipo_job.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_vetor_papeis      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE mod_crono_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN tipo_job.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_flag_padrao       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE mod_crono_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN tipo_job.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_flag_padrao       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE mod_crono_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN tipo_job.empresa_id%TYPE,
        p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_job_id IN tipo_job.tipo_job_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
END; -- TIPO_JOB_PKG



/
