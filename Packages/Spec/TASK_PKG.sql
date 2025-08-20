--------------------------------------------------------
--  DDL for Package TASK_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TASK_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_job_id            IN task.job_id%TYPE,
        p_milestone_id      IN task.milestone_id%TYPE,
        p_papel_resp_id     IN task.papel_resp_id%TYPE,
        p_desc_curta        IN task.desc_curta%TYPE,
        p_desc_detalhada    IN LONG,
        p_prioridade        IN task.prioridade%TYPE,
        p_tipo_task         IN task.tipo_task%TYPE,
        p_task_id           OUT task.task_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_task_id           IN task.task_id%TYPE,
        p_papel_resp_id     IN task.papel_resp_id%TYPE,
        p_desc_curta        IN task.desc_curta%TYPE,
        p_desc_detalhada    IN LONG,
        p_prioridade        IN task.prioridade%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_task_id           IN task.task_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE arquivo_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_arquivo_id        IN arquivo.arquivo_id%TYPE,
        p_volume_id         IN arquivo.volume_id%TYPE,
        p_task_id           IN arquivo_task.task_id%TYPE,
        p_descricao         IN arquivo.descricao%TYPE,
        p_nome_original     IN arquivo.nome_original%TYPE,
        p_nome_fisico       IN arquivo.nome_fisico%TYPE,
        p_mime_type         IN arquivo.mime_type%TYPE,
        p_tamanho           IN arquivo.tamanho%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE comentario_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_task_id           IN task_coment.task_id%TYPE,
        p_comentario        IN LONG,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE fechar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_task_id           IN task.task_id%TYPE,
        p_compl_fecham      IN task.compl_fecham%TYPE,
        p_comentario        IN LONG,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE reabrir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_task_id           IN task.task_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE historico_gerar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_task_id           IN item.item_id%TYPE,
        p_codigo            IN item_hist.codigo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE ciente_marcar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_task_hist_id      IN task_hist.task_hist_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION ciente_verificar (
        p_usuario_sessao_id IN NUMBER,
        p_task_hist_id      IN task_hist.task_hist_id%TYPE
    ) RETURN INTEGER;
 --
    FUNCTION data_evento_retornar (
        p_task_id IN task_hist.task_id%TYPE,
        p_codigo  IN task_hist.codigo%TYPE
    ) RETURN DATE;
 --
    FUNCTION usuario_id_evento_retornar (
        p_task_id IN task_hist.task_id%TYPE,
        p_codigo  IN task_hist.codigo%TYPE
    ) RETURN NUMBER;
 --
    FUNCTION situacao_retornar (
        p_task_id IN task_hist.task_id%TYPE
    ) RETURN VARCHAR2;
 --
    FUNCTION ult_comentario_retornar (
        p_task_id IN task_hist.task_id%TYPE
    ) RETURN VARCHAR2;
 --
END; -- TASK_PKG



/
