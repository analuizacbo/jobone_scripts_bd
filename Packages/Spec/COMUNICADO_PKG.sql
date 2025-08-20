--------------------------------------------------------
--  DDL for Package COMUNICADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "COMUNICADO_PKG" IS
 --
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN NUMBER,
        p_conteudo          IN comunicado.conteudo%TYPE,
        p_data_fim          IN VARCHAR2,
        p_data_inicio       IN VARCHAR2,
        p_ilustracao        IN VARCHAR2,
        p_texto_botao       IN VARCHAR2,
        p_tipo_comunicado   IN VARCHAR2,
        p_titulo            IN VARCHAR2,
        p_url               IN VARCHAR2,
        p_vetor_papel_id    IN VARCHAR2,
        p_comunicado_id     OUT comunicado.comunicado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE alterar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN NUMBER,
        p_comunicado_id       IN comunicado.comunicado_id%TYPE,
        p_arquivo_id          IN arquivo.arquivo_id%TYPE,
        p_conteudo            IN comunicado.conteudo%TYPE,
        p_data_fim            IN VARCHAR2,
        p_data_inicio         IN VARCHAR2,
        p_flag_lido_por_todos IN VARCHAR2,
        p_ilustracao          IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_texto_botao         IN VARCHAR2,
        p_tipo_comunicado     IN VARCHAR2,
        p_titulo              IN VARCHAR2,
        p_url                 IN VARCHAR2,
        p_vetor_papel_id      IN VARCHAR2,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN comunicado.empresa_id%TYPE,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE alterar_status (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_cod_acao          IN tipo_acao.codigo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE marcar_como_lido (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN comunicado.empresa_id%TYPE,
        p_comunicado_id     IN comunicado.comunicado_id%TYPE,
        p_flag_lido         IN comunicado.flag_lido_por_todos%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE arquivo_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN NUMBER,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_comunicado_id     IN arquivo_comunicado.comunicado_id%TYPE,
        p_descricao         IN arquivo.descricao%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE arquivo_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_comunicado_id IN comunicado.comunicado_id%TYPE,
        p_xml           OUT CLOB,
        p_erro_cod      OUT VARCHAR2,
        p_erro_msg      OUT VARCHAR2
    );
 --
--
END; --COMUNICADO_PKG



/
