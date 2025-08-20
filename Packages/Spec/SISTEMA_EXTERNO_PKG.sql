--------------------------------------------------------
--  DDL for Package SISTEMA_EXTERNO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SISTEMA_EXTERNO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_codigo             IN sistema_externo.codigo%TYPE,
        p_nome               IN sistema_externo.nome%TYPE,
        p_tipo_integracao_id IN sistema_externo.tipo_integracao_id%TYPE,
        p_tipo_sistema       IN sistema_externo.tipo_sistema%TYPE,
        p_sistema_externo_id OUT sistema_externo.sistema_externo_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_codigo             IN sistema_externo.codigo%TYPE,
        p_nome               IN sistema_externo.nome%TYPE,
        p_tipo_integracao_id IN sistema_externo.tipo_integracao_id%TYPE,
        p_tipo_sistema       IN sistema_externo.tipo_sistema%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE ativo_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_flag_ativo         IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE ponto_integracao_ligar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
        p_ponto_integracao_id IN ponto_integracao.ponto_integracao_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE ponto_integracao_desligar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
        p_ponto_integracao_id IN ponto_integracao.ponto_integracao_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_xml                OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END sistema_externo_pkg;


/
