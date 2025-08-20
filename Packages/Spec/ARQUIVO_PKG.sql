--------------------------------------------------------
--  DDL for Package ARQUIVO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ARQUIVO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_objeto_id         IN NUMBER,
        p_tipo_arquivo_id   IN arquivo.tipo_arquivo_id%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_descricao         IN VARCHAR2,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE palavras_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_palavras_arquivo  IN CLOB,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE id_gerar (
        p_arquivo_id OUT arquivo.arquivo_id%TYPE,
        p_erro_cod   OUT VARCHAR2,
        p_erro_msg   OUT VARCHAR2
    );
 --
END; -- ARQUIVO_PKG



/
