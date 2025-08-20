--------------------------------------------------------
--  DDL for Package FI_BANCO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FI_BANCO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_codigo            IN fi_banco.codigo%TYPE,
        p_nome              IN fi_banco.nome%TYPE,
        p_fi_banco_id       OUT fi_banco.fi_banco_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_fi_banco_id       IN fi_banco.fi_banco_id%TYPE,
        p_codigo            IN fi_banco.codigo%TYPE,
        p_nome              IN fi_banco.nome%TYPE,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_fi_banco_id       IN fi_banco.fi_banco_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_fi_banco_id IN fi_banco.fi_banco_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
END; -- FI_BANCO_PKG



/
