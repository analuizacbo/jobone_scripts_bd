--------------------------------------------------------
--  DDL for Package AREA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "AREA_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN area.nome%TYPE,
        p_flag_briefing     IN VARCHAR2,
        p_modelo_briefing   IN area.modelo_briefing%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_area_id           IN area.area_id%TYPE,
        p_nome              IN area.nome%TYPE,
        p_flag_briefing     IN VARCHAR2,
        p_modelo_briefing   IN area.modelo_briefing%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE iniciativas_atualizar (
        p_usuario_sessao_id       IN NUMBER,
        p_empresa_id              IN empresa.empresa_id%TYPE,
        p_area_id                 IN area.area_id%TYPE,
        p_vetor_dicion_emp_val_id IN VARCHAR2,
        p_erro_cod                OUT VARCHAR2,
        p_erro_msg                OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_area_id           IN area.area_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_area_id  IN area.area_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
END; -- AREA_PKG



/
