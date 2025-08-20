--------------------------------------------------------
--  DDL for Package TIPO_ARQUIVO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_ARQUIVO_PKG" IS
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_arquivo_id   IN tipo_arquivo.tipo_arquivo_id%TYPE,
        p_nome              IN tipo_arquivo.nome%TYPE,
        p_tam_max_arq       IN VARCHAR2,
        p_qtd_max_arq       IN VARCHAR2,
        p_extensoes         IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_arquivo_id IN tipo_arquivo.tipo_arquivo_id%TYPE,
        p_xml             OUT CLOB,
        p_erro_cod        OUT VARCHAR2,
        p_erro_msg        OUT VARCHAR2
    );
 --
END; -- TIPO_ARQUIVO_PKG



/
