--------------------------------------------------------
--  DDL for Package IT_CIGAM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_CIGAM_PKG" IS
 --
    PROCEDURE xml_env_cabec_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_processo           IN VARCHAR2,
        p_cod_acao           IN VARCHAR2,
        p_xml_cabecalho      OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_ret_cabec_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_servico            IN VARCHAR2,
        p_operacao           IN VARCHAR2,
        p_transacao          IN VARCHAR2,
        p_xml_cabecalho      OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_ret_msg_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_retorno        IN VARCHAR2,
        p_mensagem           IN VARCHAR2,
        p_xml_resposta       OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_retorno_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_servico            IN VARCHAR2,
        p_operacao           IN VARCHAR2,
        p_transacao          IN VARCHAR2,
        p_cod_retorno        IN VARCHAR2,
        p_mensagem           IN VARCHAR2,
        p_xml_retorno        OUT VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE nf_saida_processar (
        p_xml_in   IN CLOB,
        p_xml_out  OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
    PROCEDURE job_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_job_id             IN job.job_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE orcamento_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_orcamento_id       IN orcamento.orcamento_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_pessoa_id          IN pessoa.pessoa_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE faturamento_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_faturamento_id     IN faturamento.faturamento_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE nf_entrada_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE cigam_executar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_objeto         IN VARCHAR2,
        p_cod_acao           IN VARCHAR2,
        p_objeto_id          IN VARCHAR2,
        p_xml_in             IN CLOB,
        p_xml_out            OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT CLOB
    );
 --
    FUNCTION data_cigam_mostrar (
        p_data IN DATE
    ) RETURN VARCHAR2;
 --
    FUNCTION data_cigam_converter (
        p_data IN VARCHAR2
    ) RETURN DATE;
 --
    FUNCTION data_cigam_validar (
        p_data IN VARCHAR2
    ) RETURN INTEGER;
 --
    FUNCTION numero_cigam_converter (
        p_numero IN VARCHAR2
    ) RETURN NUMBER;
 --
    FUNCTION numero_cigam_validar (
        p_numero IN VARCHAR2
    ) RETURN INTEGER;
 --
    FUNCTION numero_cigam_mostrar (
        p_numero      IN NUMBER,
        p_casas_dec   IN INTEGER,
        p_flag_milhar IN VARCHAR2
    ) RETURN VARCHAR2;
 --
    FUNCTION uuid_retornar RETURN VARCHAR2;
 --
END; -- it_cigam_pkg



/
