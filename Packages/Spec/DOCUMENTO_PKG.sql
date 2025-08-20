--------------------------------------------------------
--  DDL for Package DOCUMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "DOCUMENTO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN documento.job_id%TYPE,
        p_papel_resp_id     IN documento.papel_resp_id%TYPE,
        p_tipo_documento_id IN documento.tipo_documento_id%TYPE,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_tipo_fluxo        IN documento.tipo_fluxo%TYPE,
        p_vetor_papel_id    IN LONG,
        p_prioridade        IN task.prioridade%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_palavras_chave    IN VARCHAR2,
        p_item_crono_id     IN item_crono.item_crono_id%TYPE,
        p_documento_id      OUT documento.documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE versao_adicionar (
        p_usuario_sessao_id    IN NUMBER,
        p_empresa_id           IN empresa.empresa_id%TYPE,
        p_flag_commit          IN VARCHAR2,
        p_job_id               IN documento.job_id%TYPE,
        p_papel_resp_id        IN documento.papel_resp_id%TYPE,
        p_documento_origem_id  IN documento.documento_id%TYPE,
        p_comentario           IN VARCHAR2,
        p_tipo_fluxo           IN documento.tipo_fluxo%TYPE,
        p_vetor_papel_id       IN LONG,
        p_prioridade           IN task.prioridade%TYPE,
        p_flag_manter_arquivos IN VARCHAR2,
        p_arquivo_id           IN arquivo.arquivo_id%TYPE,
        p_volume_id            IN arquivo.volume_id%TYPE,
        p_nome_original        IN arquivo.nome_original%TYPE,
        p_nome_fisico          IN arquivo.nome_fisico%TYPE,
        p_mime_type            IN arquivo.mime_type%TYPE,
        p_tamanho              IN arquivo.tamanho%TYPE,
        p_palavras_chave       IN VARCHAR2,
        p_documento_id         OUT documento.documento_id%TYPE,
        p_erro_cod             OUT VARCHAR2,
        p_erro_msg             OUT VARCHAR2
    );
 --
    PROCEDURE arquivo_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_documento_id      IN arquivo_documento.documento_id%TYPE,
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
    PROCEDURE arquivo_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_flag_remover      OUT VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE consolidar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_flag_reprovado    IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE task_gerar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_documento_id      IN documento.documento_id%TYPE,
        p_tipo_task         IN VARCHAR2,
        p_prioridade        IN task.prioridade%TYPE,
        p_vetor_papel_id    IN LONG,
        p_tipo_fluxo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    FUNCTION status_retornar (
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN VARCHAR2;
 --
 --
    FUNCTION status_task_retornar (
        p_task_id IN task.task_id%TYPE
    ) RETURN VARCHAR2;
 --
 --
    FUNCTION consolidado_verificar (
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER;
 --
 --
    FUNCTION prim_arquivo_id_retornar (
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER;
 --
 --
    FUNCTION qtd_arquivo_retornar (
        p_documento_id IN documento.documento_id%TYPE
    ) RETURN INTEGER;
 --
 --
    PROCEDURE xml_gerar (
        p_documento_id IN documento.documento_id%TYPE,
        p_xml          OUT CLOB,
        p_erro_cod     OUT VARCHAR2,
        p_erro_msg     OUT VARCHAR2
    );
 --
END; -- DOCUMENTO_PKG



/
