--------------------------------------------------------
--  DDL for Package NATUREZA_OPER_FATUR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "NATUREZA_OPER_FATUR_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_pessoa_id         IN natureza_oper_fatur.pessoa_id%TYPE,
        p_codigo            IN natureza_oper_fatur.codigo%TYPE,
        p_descricao         IN natureza_oper_fatur.descricao%TYPE,
        p_flag_padrao       IN natureza_oper_fatur.flag_padrao%TYPE,
        p_flag_bv           IN natureza_oper_fatur.flag_bv%TYPE,
        p_flag_servico      IN natureza_oper_fatur.flag_servico%TYPE,
        p_ordem             IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id      IN NUMBER,
        p_empresa_id             IN empresa.empresa_id%TYPE,
        p_natureza_oper_fatur_id IN natureza_oper_fatur.natureza_oper_fatur_id%TYPE,
        p_codigo                 IN natureza_oper_fatur.codigo%TYPE,
        p_descricao              IN natureza_oper_fatur.descricao%TYPE,
        p_flag_padrao            IN natureza_oper_fatur.flag_padrao%TYPE,
        p_flag_bv                IN natureza_oper_fatur.flag_bv%TYPE,
        p_flag_servico           IN natureza_oper_fatur.flag_servico%TYPE,
        p_ordem                  IN VARCHAR2,
        p_erro_cod               OUT VARCHAR2,
        p_erro_msg               OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id      IN NUMBER,
        p_empresa_id             IN empresa.empresa_id%TYPE,
        p_natureza_oper_fatur_id IN natureza_oper_fatur.natureza_oper_fatur_id%TYPE,
        p_erro_cod               OUT VARCHAR2,
        p_erro_msg               OUT VARCHAR2
    );
 --
END natureza_oper_fatur_pkg;


/
