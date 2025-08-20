--------------------------------------------------------
--  DDL for Package IT_PROTHEUS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_PROTHEUS_PKG" IS
 --
 PROCEDURE pessoa_replicar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE pessoa_cli_integrar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE pessoa_for_integrar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE pv_orcam_integrar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_orcamento_id       IN orcamento.orcamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE pv_contrato_integrar
 (
  p_sistema_externo_id  IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_cod_acao            IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE nf_entrada_integrar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );

 PROCEDURE faturamento_integrar
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_tipo_fat           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );

 PROCEDURE nf_saida_processar
 (
  p_cod_acao         IN VARCHAR2,
  p_empresa_filial   IN VARCHAR2,
  p_id_jobone_fatura IN VARCHAR2,
  p_tipo_doc         IN VARCHAR2,
  p_num_doc          IN VARCHAR2,
  p_serie            IN VARCHAR2,
  p_chave_acesso     IN VARCHAR2,
  p_data_emissao     IN VARCHAR2,
  p_desc_servico     IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_cod_ext_produto    IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_processar
 (
  p_cod_acao        IN VARCHAR2,
  p_nome            IN VARCHAR2,
  p_cod_ext_produto IN VARCHAR2,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 --
 PROCEDURE protheus_executar
 (
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
 FUNCTION uuid_retornar RETURN VARCHAR2;
 --
 FUNCTION data_protheus_converter(p_data IN VARCHAR2) RETURN DATE;
 --
 FUNCTION data_protheus_validar(p_data IN VARCHAR2) RETURN INTEGER;
 --
 FUNCTION numero_protheus_converter(p_numero IN VARCHAR2) RETURN NUMBER;
 --
 FUNCTION numero_protheus_validar(p_numero IN VARCHAR2) RETURN INTEGER;
 --
END; -- it_protheus_pkg

/
