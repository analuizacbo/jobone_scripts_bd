--------------------------------------------------------
--  DDL for Package IT_APOLO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_APOLO_PKG" IS
 --
    PROCEDURE xml_env_cabec_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_emp_resp_id        IN job.emp_resp_id%TYPE,
        p_processo           IN VARCHAR2,
        p_xml_cabecalho      OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_ret_cabec_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_processo           IN VARCHAR2,
        p_xml_cabecalho      OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_ret_msg_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_retorno        IN VARCHAR2,
        p_processo           IN VARCHAR2,
        p_objeto_id          IN VARCHAR2,
        p_mensagem           IN VARCHAR2,
        p_xml_resposta       OUT XMLTYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE xml_retorno_gerar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_retorno        IN VARCHAR2,
        p_processo           IN VARCHAR2,
        p_objeto_id          IN VARCHAR2,
        p_mensagem           IN VARCHAR2,
        p_xml_retorno        OUT VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_processar (
        p_cod_agencia IN VARCHAR2,
        p_cod_acao    IN VARCHAR2,
        p_xml_in      IN CLOB,
        p_xml_out     OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_operacao           IN VARCHAR2,
        p_tipo_pessoa        IN VARCHAR2,
        p_cod_ext_pessoa     IN VARCHAR2,
        p_apelido            IN VARCHAR2,
        p_nome               IN VARCHAR2,
        p_flag_pessoa_jur    IN VARCHAR2,
        p_flag_pessoa_ex     IN VARCHAR2,
        p_cnpj               IN VARCHAR2,
        p_inscr_estadual     IN VARCHAR2,
        p_inscr_municipal    IN VARCHAR2,
        p_inscr_inss         IN VARCHAR2,
        p_cpf                IN VARCHAR2,
        p_rg                 IN VARCHAR2,
        p_rg_org_exp         IN VARCHAR2,
        p_rg_data_exp        IN VARCHAR2,
        p_rg_uf              IN VARCHAR2,
        p_data_nasc          IN VARCHAR2,
        p_endereco           IN VARCHAR2,
        p_num_ender          IN VARCHAR2,
        p_compl_ender        IN VARCHAR2,
        p_zona               IN VARCHAR2,
        p_bairro             IN VARCHAR2,
        p_cep                IN VARCHAR2,
        p_cidade             IN VARCHAR2,
        p_uf                 IN VARCHAR2,
        p_pais               IN VARCHAR2,
        p_ddd_telefone       IN VARCHAR2,
        p_num_telefone       IN VARCHAR2,
        p_num_ramal          IN VARCHAR2,
        p_ddd_fax            IN VARCHAR2,
        p_num_fax            IN VARCHAR2,
        p_ddd_celular        IN VARCHAR2,
        p_num_celular        IN VARCHAR2,
        p_website            IN VARCHAR2,
        p_email              IN VARCHAR2,
        p_tipo_conta         IN VARCHAR2,
        p_cod_banco          IN VARCHAR2,
        p_num_agencia        IN VARCHAR2,
        p_num_conta          IN VARCHAR2,
        p_nome_titular       IN VARCHAR2,
        p_cnpj_cpf_titular   IN VARCHAR2,
        p_pessoa_id          OUT NUMBER,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE tipo_produto_processar (
        p_cod_agencia IN VARCHAR2,
        p_cod_acao    IN VARCHAR2,
        p_xml_in      IN CLOB,
        p_xml_out     OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
    PROCEDURE nf_saida_processar (
        p_cod_agencia IN VARCHAR2,
        p_cod_acao    IN VARCHAR2,
        p_xml_in      IN CLOB,
        p_xml_out     OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
    PROCEDURE carta_acordo_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
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
    PROCEDURE apolo_executar (
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
    FUNCTION data_apolo_mostrar (
        p_data IN DATE
    ) RETURN VARCHAR2;
 --
    FUNCTION data_apolo_converter (
        p_data IN VARCHAR2
    ) RETURN DATE;
 --
    FUNCTION data_apolo_validar (
        p_data IN VARCHAR2
    ) RETURN INTEGER;
 --
    FUNCTION numero_apolo_converter (
        p_numero IN VARCHAR2
    ) RETURN NUMBER;
 --
    FUNCTION numero_apolo_validar (
        p_numero IN VARCHAR2
    ) RETURN INTEGER;
 --
    FUNCTION numero_apolo_mostrar (
        p_numero      IN NUMBER,
        p_casas_dec   IN INTEGER,
        p_flag_milhar IN VARCHAR2
    ) RETURN VARCHAR2;
 --
END; -- it_apolo_pkg

/
