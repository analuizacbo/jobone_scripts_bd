--------------------------------------------------------
--  DDL for Package TIPO_CONTRATO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_CONTRATO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_codigo             IN tipo_contrato.codigo%TYPE,
        p_cod_ext_tipo       IN tipo_contrato.cod_ext_tipo%TYPE,
        p_nome               IN tipo_contrato.nome%TYPE,
        p_flag_padrao        IN VARCHAR2,
        p_flag_tem_horas     IN VARCHAR2,
        p_flag_tem_fee       IN VARCHAR2,
        p_tipo_contratante   IN tipo_contrato.tipo_contratante%TYPE,
        p_flag_verifi_precif IN tipo_contrato.flag_verifi_precif%TYPE,
        p_flag_verifi_horas  IN tipo_contrato.flag_verifi_horas%TYPE,
        p_flag_elab_contrato IN tipo_contrato.flag_elab_contrato%TYPE,
        p_flag_aloc_usuario  IN tipo_contrato.flag_aloc_usuario%TYPE,
        p_tipo_contrato_id   OUT tipo_contrato.tipo_contrato_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_tipo_contrato_id   IN tipo_contrato.tipo_contrato_id%TYPE,
        p_codigo             IN tipo_contrato.codigo%TYPE,
        p_cod_ext_tipo       IN tipo_contrato.cod_ext_tipo%TYPE,
        p_nome               IN tipo_contrato.nome%TYPE,
        p_flag_ativo         IN VARCHAR2,
        p_flag_padrao        IN VARCHAR2,
        p_flag_tem_horas     IN VARCHAR2,
        p_flag_tem_fee       IN VARCHAR2,
        p_tipo_contratante   IN tipo_contrato.tipo_contratante%TYPE,
        p_flag_verifi_precif IN tipo_contrato.flag_verifi_precif%TYPE,
        p_flag_verifi_horas  IN tipo_contrato.flag_verifi_horas%TYPE,
        p_flag_elab_contrato IN tipo_contrato.flag_elab_contrato%TYPE,
        p_flag_aloc_usuario  IN tipo_contrato.flag_aloc_usuario%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_contrato_id  IN tipo_contrato.tipo_contrato_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_contrato_id IN tipo_contrato.tipo_contrato_id%TYPE,
        p_xml              OUT CLOB,
        p_erro_cod         OUT VARCHAR2,
        p_erro_msg         OUT VARCHAR2
    );
 --
END; -- TIPO_CONTRATO_PKG



/
