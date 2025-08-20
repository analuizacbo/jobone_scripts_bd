--------------------------------------------------------
--  DDL for Package EVENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "EVENTO_PKG" IS
 --
 PROCEDURE gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cod_objeto        IN tipo_objeto.codigo%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_identif_objeto    IN historico.identif_objeto%TYPE,
  p_objeto_id         IN historico.objeto_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_xml_antes         IN CLOB,
  p_xml_atual         IN CLOB,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE carregar;
 --
 --
 PROCEDURE config_padrao_criar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_evento_id         IN evento.evento_id%TYPE,
  p_tipo_os_id        IN evento_config.tipo_os_id%TYPE,
  p_evento_config_id  OUT evento_config.evento_config_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE config_atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN evento_config.empresa_id%TYPE,
  p_evento_id              IN evento_config.evento_id%TYPE,
  p_classe_evento          IN evento.classe%TYPE,
  p_tipo_os_id             IN evento_config.tipo_os_id%TYPE,
  p_flag_historico         IN evento_config.flag_historico%TYPE,
  p_flag_notifica_tela     IN evento_config.flag_notifica_tela%TYPE,
  p_nt_flag_ender_todos    IN VARCHAR2,
  p_nt_flag_ender_papel    IN VARCHAR2,
  p_nt_vetor_ender_papel   IN VARCHAR2,
  p_nt_flag_usu_papel      IN VARCHAR2,
  p_nt_vetor_usu_papel     IN VARCHAR2,
  p_nt_flag_usu_indicado   IN VARCHAR2,
  p_nt_vetor_usu_indicado  IN VARCHAR2,
  p_nt_flag_job_criador    IN VARCHAR2,
  p_nt_flag_job_respint    IN VARCHAR2,
  p_nt_flag_ca_produtor    IN VARCHAR2,
  p_nt_flag_os_solicit     IN VARCHAR2,
  p_nt_flag_os_distr       IN VARCHAR2,
  p_nt_flag_os_exec        IN VARCHAR2,
  p_nt_flag_os_aprov       IN VARCHAR2,
  p_nt_flag_ctr_criador    IN VARCHAR2,
  p_nt_flag_ctr_respint    IN VARCHAR2,
  p_nt_flag_ad_criador     IN VARCHAR2,
  p_nt_flag_ad_solicit     IN VARCHAR2,
  p_nt_flag_ad_aprov       IN VARCHAR2,
  p_nt_flag_est_criador    IN VARCHAR2,
  p_nt_flag_est_aprov      IN VARCHAR2,
  p_nt_flag_doc_criador    IN VARCHAR2,
  p_nt_flag_doc_aprov      IN VARCHAR2,
  p_nt_flag_bri_aprov      IN VARCHAR2,
  p_nt_flag_pa_notif_ender IN VARCHAR2,
  p_flag_notifica_email    IN evento_config.flag_notifica_email%TYPE,
  p_ne_flag_ender_todos    IN VARCHAR2,
  p_ne_flag_ender_papel    IN VARCHAR2,
  p_ne_vetor_ender_papel   IN VARCHAR2,
  p_ne_flag_usu_papel      IN VARCHAR2,
  p_ne_vetor_usu_papel     IN VARCHAR2,
  p_ne_flag_usu_indicado   IN VARCHAR2,
  p_ne_vetor_usu_indicado  IN VARCHAR2,
  p_ne_flag_job_criador    IN VARCHAR2,
  p_ne_flag_job_respint    IN VARCHAR2,
  p_ne_flag_ca_produtor    IN VARCHAR2,
  p_ne_flag_os_solicit     IN VARCHAR2,
  p_ne_flag_os_distr       IN VARCHAR2,
  p_ne_flag_os_exec        IN VARCHAR2,
  p_ne_flag_os_aprov       IN VARCHAR2,
  p_ne_flag_ctr_criador    IN VARCHAR2,
  p_ne_flag_ctr_respint    IN VARCHAR2,
  p_ne_flag_ad_criador     IN VARCHAR2,
  p_ne_flag_ad_solicit     IN VARCHAR2,
  p_ne_flag_ad_aprov       IN VARCHAR2,
  p_ne_flag_est_criador    IN VARCHAR2,
  p_ne_flag_est_aprov      IN VARCHAR2,
  p_ne_flag_doc_criador    IN VARCHAR2,
  p_ne_flag_doc_aprov      IN VARCHAR2,
  p_ne_flag_bri_aprov      IN VARCHAR2,
  p_ne_flag_pa_notif_ender IN VARCHAR2,
  p_ne_flag_emails         IN VARCHAR2,
  p_ne_emails              IN VARCHAR2,
  p_notif_corpo            IN VARCHAR2,
  p_email_assunto          IN VARCHAR2,
  p_email_corpo            IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE notifica_atraso_gerar;
 --
 PROCEDURE notifica_processar;
 --
 PROCEDURE notifica_especial_processar;
 --
 PROCEDURE notifica_aprovador_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE notifica_usuario_processar
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE notifica_marcar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_notifica_fila_usu_id IN notifica_fila_usu.notifica_fila_usu_id%TYPE,
  p_flag_lido            IN notifica_fila_usu.flag_lido%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE email_enviado_marcar
 (
  p_notifica_fila_id       IN notifica_fila_email.notifica_fila_id%TYPE,
  p_notifica_fila_email_id IN notifica_fila_email.notifica_fila_email_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE motivo_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_evento_id            IN evento_motivo.evento_id%TYPE,
  p_tipo_os_id           IN evento_motivo.tipo_os_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_ordem                IN VARCHAR2,
  p_tipo_cliente_agencia IN evento_motivo.tipo_cliente_agencia%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE motivo_atualizar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_evento_motivo_id     IN evento_motivo.evento_motivo_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_ordem                IN VARCHAR2,
  p_tipo_cliente_agencia IN evento_motivo.tipo_cliente_agencia%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE motivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 FUNCTION job_id_retornar
 (
  p_cod_objeto IN tipo_objeto.codigo%TYPE,
  p_objeto_id  IN NUMBER
 ) RETURN NUMBER;
 --
 FUNCTION contrato_id_retornar
 (
  p_cod_objeto IN tipo_objeto.codigo%TYPE,
  p_objeto_id  IN NUMBER
 ) RETURN NUMBER;
 --
END; -- EVENTO_PKG

/
