--------------------------------------------------------
--  DDL for Package PAINEL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PAINEL_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_autoria           IN VARCHAR2,
        p_versao            IN VARCHAR2,
        p_data_refer        IN VARCHAR2,
        p_contato           IN VARCHAR2,
        p_url               IN VARCHAR2,
        p_origem            IN VARCHAR2,
        p_abertura          IN VARCHAR2,
        p_flag_padrao       IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_painel_id         OUT painel.painel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_painel_id         IN painel.painel_id%TYPE,
        p_flag_usuario_id   IN VARCHAR2,
        p_nome              IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_autoria           IN VARCHAR2,
        p_versao            IN VARCHAR2,
        p_data_refer        IN VARCHAR2,
        p_contato           IN VARCHAR2,
        p_url               IN VARCHAR2,
        p_origem            IN VARCHAR2,
        p_dash_numero       IN VARCHAR2,
        p_api_key           IN VARCHAR2,
        p_abertura          IN VARCHAR2,
        p_flag_padrao       IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_painel_id         IN painel.painel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE padrao_papel_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_painel_id         IN painel.painel_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_flag_padrao       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE papel_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_painel_id         IN painel.painel_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_flag_padrao       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE papel_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_painel_id         IN painel.painel_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_painel_id IN painel.painel_id%TYPE,
        p_xml       OUT CLOB,
        p_erro_cod  OUT VARCHAR2,
        p_erro_msg  OUT VARCHAR2
    );
 --
    PROCEDURE cenario_status_alterar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_cenario_id        IN cenario.cenario_id%TYPE,
        p_cod_acao          IN tipo_acao.codigo%TYPE,
        p_complemento       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE cenario_servico_status_alterar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_flag_commit        IN VARCHAR2,
        p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
        p_cod_acao           IN tipo_acao.codigo%TYPE,
        p_complemento        IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- PAINEL_PKG

/
