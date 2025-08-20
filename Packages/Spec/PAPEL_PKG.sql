--------------------------------------------------------
--  DDL for Package PAPEL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PAPEL_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id            IN usuario.usuario_id%TYPE,
        p_empresa_id                   IN empresa.empresa_id%TYPE,
        p_area_id                      IN papel.area_id%TYPE,
        p_nome                         IN papel.nome%TYPE,
        p_flag_ender                   IN papel.flag_ender%TYPE,
        p_flag_auto_ender              IN papel.flag_auto_ender%TYPE,
        p_flag_auto_ender_ctr          IN papel.flag_auto_ender_ctr%TYPE,
        p_flag_auto_ender_oport        IN papel.flag_auto_ender_oport%TYPE,
        p_flag_notif_ender             IN papel.flag_notif_ender%TYPE,
        p_flag_apontam_form            IN papel.flag_apontam_form%TYPE,
        p_ordem                        IN VARCHAR2,
        p_vetor_tipo_pessoa_id_v_geral IN VARCHAR2,
        p_vetor_tipo_pessoa_id_v_somen IN VARCHAR2,
        p_flag_tipo_pessoa_v_todos     IN VARCHAR2,
        p_vetor_tipo_pessoa_id_c_geral IN VARCHAR2,
        p_vetor_tipo_pessoa_id_c_somen IN VARCHAR2,
        p_flag_tipo_pessoa_c_todos     IN VARCHAR2,
        p_vetor_configurar_priv_id     IN VARCHAR2,
        p_vetor_oportun_priv_id        IN VARCHAR2,
        p_vetor_oportunend_priv_id     IN VARCHAR2,
        p_vetor_oportunend_abrang      IN VARCHAR2,
        p_vetor_contrato_priv_id       IN VARCHAR2,
        p_vetor_contratoend_priv_id    IN VARCHAR2,
        p_vetor_contratoend_abrang     IN VARCHAR2,
        p_vetor_job_priv_id            IN VARCHAR2,
        p_vetor_jobend_priv_id         IN VARCHAR2,
        p_vetor_jobend_abrang          IN VARCHAR2,
        p_vetor_orcend_priv_id         IN VARCHAR2,
        p_vetor_orcend_abrang          IN VARCHAR2,
        p_vetor_tipo_job_id            IN VARCHAR2,
        p_vetor_tipo_financeiro_id     IN VARCHAR2,
        p_vetor_enderecar_area_id      IN VARCHAR2,
        p_vetor_enderecar_abrang       IN VARCHAR2,
        p_vetor_entrega_priv_id        IN VARCHAR2,
        p_vetor_entrega_tipo_os_id     IN VARCHAR2,
        p_vetor_entrega_abrang         IN VARCHAR2,
        p_vetor_monitorar_priv_id      IN VARCHAR2,
        p_vetor_analisar_priv_id       IN VARCHAR2,
        p_vetor_docum_priv_id          IN VARCHAR2,
        p_vetor_docum_tipo_doc_id      IN VARCHAR2,
        p_vetor_docum_abrang           IN VARCHAR2,
        p_vetor_apontam_priv_id        IN VARCHAR2,
        p_vetor_navegacao_priv_id      IN VARCHAR2,
        p_vetor_painel_id              IN VARCHAR2,
        p_painel_pdr_id                IN VARCHAR2,
        p_vetor_oportunender_area_id   IN VARCHAR2,
        p_vetor_oportunender_abrang    IN VARCHAR2,
        p_vetor_contratoender_area_id  IN VARCHAR2,
        p_vetor_contratoender_abrang   IN VARCHAR2,
        p_erro_cod                     OUT VARCHAR2,
        p_erro_msg                     OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id            IN usuario.usuario_id%TYPE,
        p_empresa_id                   IN empresa.empresa_id%TYPE,
        p_papel_id                     IN papel.papel_id%TYPE,
        p_area_id                      IN papel.area_id%TYPE,
        p_nome                         IN papel.nome%TYPE,
        p_flag_ender                   IN papel.flag_ender%TYPE,
        p_flag_auto_ender              IN papel.flag_auto_ender%TYPE,
        p_flag_auto_ender_ctr          IN papel.flag_auto_ender_ctr%TYPE,
        p_flag_auto_ender_oport        IN papel.flag_auto_ender_oport%TYPE,
        p_flag_notif_ender             IN papel.flag_notif_ender%TYPE,
        p_flag_apontam_form            IN papel.flag_apontam_form%TYPE,
        p_flag_ativo                   IN papel.flag_ativo%TYPE,
        p_ordem                        IN VARCHAR2,
        p_vetor_tipo_pessoa_id_v_geral IN VARCHAR2,
        p_vetor_tipo_pessoa_id_v_somen IN VARCHAR2,
        p_flag_tipo_pessoa_v_todos     IN VARCHAR2,
        p_vetor_tipo_pessoa_id_c_geral IN VARCHAR2,
        p_vetor_tipo_pessoa_id_c_somen IN VARCHAR2,
        p_flag_tipo_pessoa_c_todos     IN VARCHAR2,
        p_vetor_configurar_priv_id     IN VARCHAR2,
        p_vetor_oportun_priv_id        IN VARCHAR2,
        p_vetor_oportunend_priv_id     IN VARCHAR2,
        p_vetor_oportunend_abrang      IN VARCHAR2,
        p_vetor_contrato_priv_id       IN VARCHAR2,
        p_vetor_contratoend_priv_id    IN VARCHAR2,
        p_vetor_contratoend_abrang     IN VARCHAR2,
        p_vetor_job_priv_id            IN VARCHAR2,
        p_vetor_jobend_priv_id         IN VARCHAR2,
        p_vetor_jobend_abrang          IN VARCHAR2,
        p_vetor_orcend_priv_id         IN VARCHAR2,
        p_vetor_orcend_abrang          IN VARCHAR2,
        p_vetor_tipo_job_id            IN VARCHAR2,
        p_vetor_tipo_financeiro_id     IN VARCHAR2,
        p_vetor_enderecar_area_id      IN VARCHAR2,
        p_vetor_enderecar_abrang       IN VARCHAR2,
        p_vetor_entrega_priv_id        IN VARCHAR2,
        p_vetor_entrega_tipo_os_id     IN VARCHAR2,
        p_vetor_entrega_abrang         IN VARCHAR2,
        p_vetor_monitorar_priv_id      IN VARCHAR2,
        p_vetor_analisar_priv_id       IN VARCHAR2,
        p_vetor_docum_priv_id          IN VARCHAR2,
        p_vetor_docum_tipo_doc_id      IN VARCHAR2,
        p_vetor_docum_abrang           IN VARCHAR2,
        p_vetor_apontam_priv_id        IN VARCHAR2,
        p_vetor_navegacao_priv_id      IN VARCHAR2,
        p_vetor_painel_id              IN VARCHAR2,
        p_painel_pdr_id                IN VARCHAR2,
        p_vetor_oportunender_area_id   IN VARCHAR2,
        p_vetor_oportunender_abrang    IN VARCHAR2,
        p_vetor_contratoender_area_id  IN VARCHAR2,
        p_vetor_contratoender_abrang   IN VARCHAR2,
        p_erro_cod                     OUT VARCHAR2,
        p_erro_msg                     OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN usuario.usuario_id%TYPE,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE copiar (
        p_usuario_sessao_id IN usuario.usuario_id%TYPE,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_papel_id IN papel.papel_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
END papel_pkg;


/
