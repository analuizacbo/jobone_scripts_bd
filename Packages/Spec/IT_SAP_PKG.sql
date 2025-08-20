--------------------------------------------------------
--  DDL for Package IT_SAP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_SAP_PKG" IS
 --
    PROCEDURE pessoa_processar (
        p_cod_acao       IN VARCHAR2,
        p_tipo_pessoa    IN VARCHAR2,
        p_cod_emp_sap    IN VARCHAR2,
        p_cod_filial_sap IN VARCHAR2,
        p_cod_cli_sap    IN VARCHAR2,
        p_apelido        IN VARCHAR2,
        p_nome           IN VARCHAR2,
        p_cod_projeto    IN VARCHAR2,
        p_tipo_fis_jur   IN VARCHAR2,
        p_cnpj           IN VARCHAR2,
        p_cpf            IN VARCHAR2,
        p_pais           IN VARCHAR2,
        p_uf             IN VARCHAR2,
        p_cidade         IN VARCHAR2,
        p_bairro         IN VARCHAR2,
        p_cep            IN VARCHAR2,
        p_endereco       IN VARCHAR2,
        p_complemento    IN VARCHAR2,
        p_telefone       IN VARCHAR2,
        p_fax            IN VARCHAR2,
        p_email          IN VARCHAR2,
        p_ativo          IN VARCHAR2,
        p_pessoa_id      OUT VARCHAR2,
        p_erro_cod       OUT VARCHAR2,
        p_erro_msg       OUT VARCHAR2
    );
 --
    PROCEDURE pessoa_atualizar (
        p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_emp_resp_pdr_id    IN pessoa.emp_resp_pdr_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_tipo_pessoa        IN VARCHAR2,
  p_cod_ext_pessoa     IN VARCHAR2,
  p_cod_job            IN VARCHAR2,
  p_pessoa_fis_jur     IN VARCHAR2,
  p_apelido            IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_cnpj               IN VARCHAR2,
  p_cpf                IN VARCHAR2,
  p_endereco           IN VARCHAR2,
  p_num_ender          IN VARCHAR2,
  p_compl_ender        IN VARCHAR2,
  p_bairro             IN VARCHAR2,
  p_cep                IN VARCHAR2,
  p_cidade             IN VARCHAR2,
  p_uf                 IN VARCHAR2,
  p_pais               IN VARCHAR2,
  p_telefone           IN VARCHAR2,
  p_fax                IN VARCHAR2,
  p_email              IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_pessoa_id          OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE produto_cliente_processar (
        p_cod_acao           IN VARCHAR2,
        p_cod_emp_sap        IN VARCHAR2,
        p_cod_cli_sap        IN VARCHAR2,
        p_cod_pro_sap        IN VARCHAR2,
        p_nome               IN VARCHAR2,
        p_ativo              IN VARCHAR2,
        p_produto_cliente_id OUT NUMBER,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE produto_cliente_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_operacao           IN VARCHAR2,
        p_cod_ext_cliente    IN VARCHAR2,
        p_cod_ext_produto    IN VARCHAR2,
        p_nome               IN VARCHAR2,
        p_flag_ativo         IN VARCHAR2,
        p_produto_cliente_id OUT NUMBER,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE tipo_produto_processar (
        p_cod_acao         IN VARCHAR2,
        p_cod_emp_sap      IN VARCHAR2,
        p_cod_material_sap IN VARCHAR2,
        p_nome             IN VARCHAR2,
        p_categoria        IN VARCHAR2,
        p_ativo            IN VARCHAR2,
        p_tipo_produto_id  OUT NUMBER,
        p_erro_cod         OUT VARCHAR2,
        p_erro_msg         OUT VARCHAR2
    );
 --
    PROCEDURE tipo_produto_atualizar (
        p_usuario_sessao_id  IN NUMBER,
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_operacao           IN VARCHAR2,
        p_cod_ext_produto    IN VARCHAR2,
        p_nome               IN VARCHAR2,
        p_categoria          IN VARCHAR2,
        p_flag_ativo         IN VARCHAR2,
        p_tipo_produto_id    OUT NUMBER,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE ordem_servico_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
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
    PROCEDURE carta_acordo_integrar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
        p_cod_acao           IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE carta_acordo_processar (
        p_cod_emp_sap     IN VARCHAR2,
        p_carta_acordo_id IN VARCHAR2,
        p_cod_ext_carta   IN VARCHAR2,
        p_erro_cod        OUT VARCHAR2,
        p_erro_msg        OUT VARCHAR2
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
    PROCEDURE sap_executar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_cod_objeto         IN VARCHAR2,
        p_cod_acao           IN VARCHAR2,
        p_objeto_id          IN VARCHAR2,
        p_xml_in             IN CLOB,
        p_xml_out            OUT CLOB,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- it_sap_pkg

/
