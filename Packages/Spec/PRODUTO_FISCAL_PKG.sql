--------------------------------------------------------
--  DDL for Package PRODUTO_FISCAL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PRODUTO_FISCAL_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN produto_fiscal.nome%TYPE,
        p_categoria         IN produto_fiscal.categoria%TYPE,
        p_cod_ext_produto   IN produto_fiscal.cod_ext_produto%TYPE,
        p_flag_ativo        IN produto_fiscal.flag_ativo%TYPE,
        p_produto_fiscal_id OUT produto_fiscal.produto_fiscal_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_produto_fiscal_id IN produto_fiscal.produto_fiscal_id%TYPE,
        p_nome              IN produto_fiscal.nome%TYPE,
        p_categoria         IN produto_fiscal.categoria%TYPE,
        p_cod_ext_produto   IN produto_fiscal.cod_ext_produto%TYPE,
        p_flag_ativo        IN produto_fiscal.flag_ativo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_produto_fiscal_id IN produto_fiscal.produto_fiscal_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_produto_fiscal_id IN produto_fiscal.produto_fiscal_id%TYPE,
        p_xml               OUT CLOB,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- PRODUTO_FISCAL_PKG



/
