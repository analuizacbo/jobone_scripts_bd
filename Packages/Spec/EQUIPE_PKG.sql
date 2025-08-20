--------------------------------------------------------
--  DDL for Package EQUIPE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "EQUIPE_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN equipe.nome%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_nome              IN equipe.nome%TYPE,
        p_flag_em_dist_os   IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE usuario_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_usuario_id        IN usuario.usuario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE usuario_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_usuario_id        IN usuario.usuario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE guide_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_usuario_id        IN usuario.usuario_id%TYPE,
        p_flag_guide        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE membro_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_usuario_id        IN usuario.usuario_id%TYPE,
        p_flag_membro       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE responsavel_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_usuario_id        IN usuario.usuario_id%TYPE,
        p_flag_responsavel  IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE tipo_tarefa_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_tipo_tarefa_id    IN equipe.tipo_tarefa_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_equipe_id IN equipe.equipe_id%TYPE,
        p_xml       OUT CLOB,
        p_erro_cod  OUT VARCHAR2,
        p_erro_msg  OUT VARCHAR2
    );
 --
END; -- EQUIPE_PKG



/
