--------------------------------------------------------
--  DDL for Package TIPO_FINANCEIRO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_FINANCEIRO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_codigo                IN tipo_financeiro.codigo%TYPE,
        p_nome                  IN tipo_financeiro.nome%TYPE,
        p_flag_despesa          IN VARCHAR2,
        p_flag_consid_hr_os_ctr IN VARCHAR2,
        p_flag_padrao           IN VARCHAR2,
        p_tipo_custo            IN VARCHAR2,
        p_cod_job               IN VARCHAR2,
        p_flag_usa_budget       IN VARCHAR2,
        p_flag_usa_receita_prev IN VARCHAR2,
        p_flag_obriga_contrato  IN VARCHAR2,
        p_tipo_financeiro_id    OUT tipo_financeiro.tipo_financeiro_id%TYPE,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_tipo_financeiro_id    IN tipo_financeiro.tipo_financeiro_id%TYPE,
        p_codigo                IN tipo_financeiro.codigo%TYPE,
        p_nome                  IN tipo_financeiro.nome%TYPE,
        p_flag_despesa          IN VARCHAR2,
        p_flag_consid_hr_os_ctr IN VARCHAR2,
        p_flag_padrao           IN VARCHAR2,
        p_tipo_custo            IN VARCHAR2,
        p_cod_job               IN VARCHAR2,
        p_flag_usa_budget       IN VARCHAR2,
        p_flag_usa_receita_prev IN VARCHAR2,
        p_flag_obriga_contrato  IN VARCHAR2,
        p_flag_ativo            IN VARCHAR2,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE papel_priv_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN tipo_financeiro.empresa_id%TYPE,
        p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
        p_vetor_papeis       IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
        p_xml                OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- TIPO_FINANCEIRO_PKG



/
