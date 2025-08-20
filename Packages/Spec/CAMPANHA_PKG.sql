--------------------------------------------------------
--  DDL for Package CAMPANHA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CAMPANHA_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_cliente_id        IN campanha.cliente_id%TYPE,
        p_cod_ext_camp      IN campanha.cod_ext_camp%TYPE,
        p_nome              IN campanha.nome%TYPE,
        p_data_ini          IN VARCHAR2,
        p_data_fim          IN VARCHAR2,
        p_campanha_id       OUT NUMBER,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_campanha_id       IN campanha.campanha_id%TYPE,
        p_cod_ext_camp      IN campanha.cod_ext_camp%TYPE,
        p_nome              IN campanha.nome%TYPE,
        p_data_ini          IN VARCHAR2,
        p_data_fim          IN VARCHAR2,
        p_flag_ativo        IN campanha.flag_ativo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_campanha_id       IN campanha.campanha_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_campanha_id IN campanha.campanha_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
END; -- CAMPANHA_PKG



/
