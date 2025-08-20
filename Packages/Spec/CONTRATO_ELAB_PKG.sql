--------------------------------------------------------
--  DDL for Package CONTRATO_ELAB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CONTRATO_ELAB_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN contrato.empresa_id%TYPE,
        p_contrato_id       IN contrato.contrato_id%TYPE,
        p_cod_contrato_elab IN contrato_elab.cod_contrato_elab%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE acao_executar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN contrato.empresa_id%TYPE,
        p_contrato_elab_id  IN contrato_elab.contrato_elab_id%TYPE,
        p_cod_acao          IN ct_transicao.cod_acao%TYPE,
        p_motivo            IN contrato_elab.motivo%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END;
-- CONTRATO_ELAB_PKG



/
