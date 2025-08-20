--------------------------------------------------------
--  DDL for Package TIPO_APONTAM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_APONTAM_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_codigo             IN tipo_apontam.codigo%TYPE,
        p_nome               IN tipo_apontam.nome%TYPE,
        p_grupo              IN tipo_apontam.grupo%TYPE,
        p_flag_billable      IN VARCHAR2,
        p_flag_sistema       IN VARCHAR2,
        p_flag_ativo         IN VARCHAR2,
        p_flag_ausencia      IN VARCHAR2,
        p_flag_ausencia_full IN VARCHAR2,
        p_flag_formulario    IN VARCHAR2,
        p_tipo_apontam_id    OUT tipo_apontam.tipo_apontam_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
        p_codigo             IN tipo_apontam.codigo%TYPE,
        p_nome               IN tipo_apontam.nome%TYPE,
        p_grupo              IN tipo_apontam.grupo%TYPE,
        p_flag_billable      IN VARCHAR2,
        p_flag_sistema       IN VARCHAR2,
        p_flag_ativo         IN VARCHAR2,
        p_flag_ausencia      IN VARCHAR2,
        p_flag_ausencia_full IN VARCHAR2,
        p_flag_formulario    IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_apontam_id   IN tipo_apontam.tipo_apontam_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_apontam_id IN tipo_apontam.tipo_apontam_id%TYPE,
        p_xml             OUT CLOB,
        p_erro_cod        OUT VARCHAR2,
        p_erro_msg        OUT VARCHAR2
    );

END; -- TIPO_APONTAM_PKG



/
