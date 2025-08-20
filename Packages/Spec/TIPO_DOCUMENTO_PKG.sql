--------------------------------------------------------
--  DDL for Package TIPO_DOCUMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_DOCUMENTO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_codigo            IN tipo_documento.codigo%TYPE,
        p_nome              IN tipo_documento.nome%TYPE,
        p_ordem_cli         IN VARCHAR2,
        p_flag_visivel_cli  IN VARCHAR2,
        p_tam_max_arq       IN VARCHAR2,
        p_qtd_max_arq       IN VARCHAR2,
        p_extensoes         IN VARCHAR2,
        p_flag_tem_aprov    IN VARCHAR2,
        p_flag_tem_comen    IN VARCHAR2,
        p_flag_tem_cienc    IN VARCHAR2,
        p_tipo_documento_id OUT tipo_documento.tipo_documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
        p_codigo            IN tipo_documento.codigo%TYPE,
        p_nome              IN tipo_documento.nome%TYPE,
        p_ordem_cli         IN VARCHAR2,
        p_flag_visivel_cli  IN VARCHAR2,
        p_tam_max_arq       IN VARCHAR2,
        p_qtd_max_arq       IN VARCHAR2,
        p_extensoes         IN VARCHAR2,
        p_flag_tem_aprov    IN VARCHAR2,
        p_flag_tem_comen    IN VARCHAR2,
        p_flag_tem_cienc    IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
        p_xml               OUT CLOB,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- TIPO_DOCUMENTO_PKG



/
