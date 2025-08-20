--------------------------------------------------------
--  DDL for Package UNIDADE_NEGOCIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "UNIDADE_NEGOCIO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_nome               IN unidade_negocio.nome%TYPE,
        p_cod_ext_unid_neg   IN VARCHAR2,
        p_flag_qualquer_job  IN VARCHAR2,
        p_unidade_negocio_id OUT unidade_negocio.unidade_negocio_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_nome               IN unidade_negocio.nome%TYPE,
        p_cod_ext_unid_neg   IN VARCHAR2,
        p_flag_qualquer_job  IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE cliente_adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_cliente_id         IN unidade_negocio_cli.cliente_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE cliente_excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_cliente_id         IN unidade_negocio_cli.cliente_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE usuario_adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE usuario_excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE usu_ender_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
        p_flag_enderecar     IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE usu_resp_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
        p_flag_responsavel   IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
 --
    PROCEDURE usu_rateio_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_usuario_id        IN unidade_negocio_usu.usuario_id%TYPE,
        p_vetor_unid_neg_id IN VARCHAR2,
        p_vetor_perc_rateio IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
        p_xml                OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- UNIDADE_NEGOCIO_PKG



/
