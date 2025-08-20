--------------------------------------------------------
--  DDL for Package SERVICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SERVICO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_margem_oper_min   IN VARCHAR2,
        p_margem_oper_meta  IN VARCHAR2,
        p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
        p_flag_tem_comissao IN VARCHAR2,
        p_servico_id        OUT servico.servico_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_servico_id        IN servico.servico_id%TYPE,
        p_nome              IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_margem_oper_min   IN VARCHAR2,
        p_margem_oper_meta  IN VARCHAR2,
        p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
        p_flag_ativo        IN VARCHAR2,
        p_flag_tem_comissao IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_servico_id        IN servico.servico_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE grupo_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN VARCHAR2,
        p_grupo_servico_id  OUT grupo_servico.grupo_servico_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE grupo_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
        p_nome              IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE grupo_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_servico_id IN servico.servico_id%TYPE,
        p_xml        OUT CLOB,
        p_erro_cod   OUT VARCHAR2,
        p_erro_msg   OUT VARCHAR2
    );
 --
END; -- SERVICO_PKG



/
