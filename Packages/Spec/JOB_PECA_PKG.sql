--------------------------------------------------------
--  DDL for Package JOB_PECA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "JOB_PECA_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job_peca.job_id%TYPE,
        p_tipo_peca_id      IN job_peca.tipo_peca_id%TYPE,
        p_complemento       IN job_peca.complemento%TYPE,
        p_especificacao     IN VARCHAR2,
        p_obs               IN VARCHAR2,
        p_tipo_solicitacao  IN VARCHAR2,
        p_data_prazo        IN VARCHAR2,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_peca_id       IN job_peca.job_peca_id%TYPE,
        p_tipo_peca_id      IN job_peca.tipo_peca_id%TYPE,
        p_complemento       IN job_peca.complemento%TYPE,
        p_especificacao     IN VARCHAR2,
        p_obs               IN VARCHAR2,
        p_tipo_solicitacao  IN VARCHAR2,
        p_data_prazo        IN VARCHAR2,
        p_ref_arquivo_id    IN arquivo.arquivo_id%TYPE,
        p_ref_volume_id     IN arquivo.volume_id%TYPE,
        p_ref_nome_original IN arquivo.nome_original%TYPE,
        p_ref_nome_fisico   IN arquivo.nome_fisico%TYPE,
        p_ref_mime_type     IN arquivo.mime_type%TYPE,
        p_ref_tamanho       IN arquivo.tamanho%TYPE,
        p_cri_arquivo_id    IN arquivo.arquivo_id%TYPE,
        p_cri_volume_id     IN arquivo.volume_id%TYPE,
        p_cri_nome_original IN arquivo.nome_original%TYPE,
        p_cri_nome_fisico   IN arquivo.nome_fisico%TYPE,
        p_cri_mime_type     IN arquivo.mime_type%TYPE,
        p_cri_tamanho       IN arquivo.tamanho%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE documento_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_peca_id       IN job_peca.job_peca_id%TYPE,
        p_documento_id      IN documento.documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_peca_id       IN job_peca.job_peca_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE cancelar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_peca_id       IN job_peca.job_peca_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE concluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_peca_id       IN job_peca.job_peca_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION ult_peca_retornar (
        p_job_id       IN job.job_id%TYPE,
        p_tipo_peca_id IN job_peca.tipo_peca_id%TYPE,
        p_complemento  IN job_peca.complemento%TYPE
    ) RETURN INTEGER;
 --
    FUNCTION ult_doc_retornar (
        p_job_id       IN job.job_id%TYPE,
        p_tipo_peca_id IN job_peca.tipo_peca_id%TYPE,
        p_complemento  IN job_peca.complemento%TYPE,
        p_tipo_doc     IN tipo_documento.codigo%TYPE
    ) RETURN INTEGER;
 --
END; -- JOB_PECA_PKG



/
