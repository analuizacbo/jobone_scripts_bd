--------------------------------------------------------
--  DDL for Package ADIANT_DESP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ADIANT_DESP_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_motivo_adiant     IN adiant_desp.motivo_adiant%TYPE,
  p_complemento       IN VARCHAR2,
  p_data_limite       IN VARCHAR2,
  p_hora_limite       IN VARCHAR2,
  p_valor_solicitado  IN VARCHAR2,
  p_forma_adiant_pref IN adiant_desp.forma_adiant_pref%TYPE,
  p_solicitante_id    IN adiant_desp.solicitante_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_valor       IN VARCHAR2,
  p_adiant_desp_id    OUT adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_motivo_adiant     IN adiant_desp.motivo_adiant%TYPE,
  p_complemento       IN VARCHAR2,
  p_data_limite       IN VARCHAR2,
  p_hora_limite       IN VARCHAR2,
  p_valor_solicitado  IN VARCHAR2,
  p_forma_adiant_pref IN adiant_desp.forma_adiant_pref%TYPE,
  p_solicitante_id    IN adiant_desp.solicitante_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_valor       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE terminar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE retomar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE encerrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reabrir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE realizado_adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_adiant_desp_id      IN adiant_realiz.adiant_desp_id%TYPE,
  p_forma_adiant        IN adiant_realiz.forma_adiant%TYPE,
  p_valor_realiz        IN VARCHAR2,
  p_fi_banco_id         IN adiant_realiz.fi_banco_id%TYPE,
  p_num_agencia         IN adiant_realiz.num_agencia%TYPE,
  p_num_conta           IN adiant_realiz.num_conta%TYPE,
  p_tipo_conta          IN adiant_realiz.tipo_conta%TYPE,
  p_cnpj_cpf_titular    IN VARCHAR2,
  p_nome_titular        IN VARCHAR2,
  p_flag_atualiza_conta IN VARCHAR2,
  p_adiant_realiz_id    OUT adiant_realiz.adiant_realiz_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE realizado_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_realiz_id  IN adiant_realiz.adiant_realiz_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE despesa_adicionar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_adiant_desp_id        IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_desp       IN VARCHAR2,
  p_vetor_tipo_produto_id IN VARCHAR2,
  p_vetor_complemento     IN VARCHAR2,
  p_vetor_fornecedor      IN VARCHAR2,
  p_vetor_num_doc         IN VARCHAR2,
  p_vetor_serie           IN VARCHAR2,
  p_vetor_valor_desp      IN VARCHAR2,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_valor_desp_it   IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE despesa_atualizar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_adiant_desp_id        IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_desp       IN VARCHAR2,
  p_vetor_tipo_produto_id IN VARCHAR2,
  p_vetor_complemento     IN VARCHAR2,
  p_vetor_fornecedor      IN VARCHAR2,
  p_vetor_num_doc         IN VARCHAR2,
  p_vetor_serie           IN VARCHAR2,
  p_vetor_valor_desp      IN VARCHAR2,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_valor_desp_it   IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE devolucao_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_adiant_desp_id       IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_devol     IN VARCHAR2,
  p_vetor_forma_devol    IN VARCHAR2,
  p_vetor_complemento    IN VARCHAR2,
  p_vetor_valor_devol    IN VARCHAR2,
  p_vetor_item_id        IN VARCHAR2,
  p_vetor_valor_devol_it IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE devolucao_atualizar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_adiant_desp_id       IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_devol     IN VARCHAR2,
  p_vetor_forma_devol    IN VARCHAR2,
  p_vetor_complemento    IN VARCHAR2,
  p_vetor_valor_devol    IN VARCHAR2,
  p_vetor_item_id        IN VARCHAR2,
  p_vetor_valor_devol_it IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 );
 --
 --
 FUNCTION numero_formatar
 (
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
  p_flag_prefixo   IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 FUNCTION valor_retornar
 (
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
  p_tipo_valor     IN VARCHAR2
 ) RETURN NUMBER;
 --
END; -- ADIANT_DESP_PKG

/
