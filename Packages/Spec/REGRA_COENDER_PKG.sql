--------------------------------------------------------
--  DDL for Package REGRA_COENDER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "REGRA_COENDER_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id      IN NUMBER,
        p_empresa_id             IN empresa.empresa_id%TYPE,
        p_grupo_id               IN regra_coender.grupo_id%TYPE,
        p_cliente_id             IN regra_coender.cliente_id%TYPE,
        p_produto_cliente_id     IN regra_coender.produto_cliente_id%TYPE,
        p_tipo_job_id            IN regra_coender.tipo_job_id%TYPE,
        p_descricao              IN VARCHAR2,
        p_flag_ativo             IN VARCHAR2,
        p_comentario             IN VARCHAR2,
        p_vetor_usuario_end_id   IN VARCHAR2,
        p_vetor_usuario_coend_id IN VARCHAR2,
        p_regra_coender_id       OUT regra_coender.regra_coender_id%TYPE,
        p_erro_cod               OUT VARCHAR2,
        p_erro_msg               OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_regra_coender_id   IN regra_coender.regra_coender_id%TYPE,
        p_grupo_id           IN regra_coender.grupo_id%TYPE,
        p_cliente_id         IN regra_coender.cliente_id%TYPE,
        p_produto_cliente_id IN regra_coender.produto_cliente_id%TYPE,
        p_tipo_job_id        IN regra_coender.tipo_job_id%TYPE,
        p_descricao          IN VARCHAR2,
        p_comentario         IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE usuario_ender_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
        p_vetor_usuario_id  IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE usuario_coender_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
        p_vetor_usuario_id  IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE flag_ativo_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
        p_flag_ativo        IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE copiar (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_regra_coender_id      IN regra_coender.regra_coender_id%TYPE,
        p_regra_coender_novo_id OUT regra_coender.regra_coender_id%TYPE,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_regra_coender_id  IN regra_coender.regra_coender_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_regra_coender_id IN regra_coender.regra_coender_id%TYPE,
        p_xml              OUT CLOB,
        p_erro_cod         OUT VARCHAR2,
        p_erro_msg         OUT VARCHAR2
    );
 --
END; -- REGRA_COENDER_PKG



/
