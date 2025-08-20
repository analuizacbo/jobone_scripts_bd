--------------------------------------------------------
--  DDL for Package COMENTARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "COMENTARIO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_tipo_objeto       IN VARCHAR2,
        p_objeto_id         IN comentario.objeto_id%TYPE,
        p_classe            IN comentario.classe%TYPE,
        p_comentario_pai_id IN comentario.comentario_pai_id%TYPE,
        p_comentario        IN comentario.comentario%TYPE,
        p_comentario_id     OUT comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE enderecados_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_vetor_enderecados IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE ocultar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_comentario_id     IN comentario.comentario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- COMENTARIO_PKG



/
