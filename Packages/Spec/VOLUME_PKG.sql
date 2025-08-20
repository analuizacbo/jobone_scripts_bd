--------------------------------------------------------
--  DDL for Package VOLUME_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "VOLUME_PKG" IS
 --
    PROCEDURE retornar (
        p_servidor_arquivo_id IN servidor_arquivo.servidor_arquivo_id%TYPE,
        p_tipo_objeto         IN volume.prefixo%TYPE,
        p_volume_id           OUT volume.volume_id%TYPE,
        p_numero              OUT volume.numero%TYPE,
        p_caminho             OUT volume.caminho%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id   IN NUMBER,
        p_flag_commit         IN VARCHAR2,
        p_servidor_arquivo_id IN servidor_arquivo.servidor_arquivo_id%TYPE,
        p_prefixo             IN volume.prefixo%TYPE,
        p_numero              IN VARCHAR2,
        p_caminho             IN volume.caminho%TYPE,
        p_status              IN volume.status%TYPE,
        p_volume_id           OUT volume.volume_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_volume_id         IN volume.volume_id%TYPE,
        p_prefixo           IN volume.prefixo%TYPE,
        p_numero            IN VARCHAR2,
        p_caminho           IN volume.caminho%TYPE,
        p_status            IN volume.status%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_volume_id         IN volume.volume_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION caminho_completo_retornar (
        p_volume_id IN volume.volume_id%TYPE
    ) RETURN VARCHAR2;
 --
END; -- VOLUME_PKG



/
