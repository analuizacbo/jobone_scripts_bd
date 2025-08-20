--------------------------------------------------------
--  DDL for Package OPORTUNIDADE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "OPORTUNIDADE_PKG" IS
 --
 PROCEDURE consistir_principal
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_tipo_chamada         IN VARCHAR2,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_cliente_id           IN oportunidade.cliente_id%TYPE,
  p_flag_conflito        IN VARCHAR2,
  p_cliente_conflito_id  IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id           IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id   IN oportunidade.produto_cliente_id%TYPE,
  p_usuario_resp_id      IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN oportunidade.unid_negocio_resp_id%TYPE,
  p_origem               IN oportunidade.origem%TYPE,
  p_compl_origem         IN VARCHAR2,
  p_tipo_negocio         IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id     IN oportunidade.tipo_contrato_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_wizard
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_preco_id                IN tab_preco.preco_id%TYPE,
  p_nome                    IN oportunidade.nome%TYPE,
  p_cliente_id              IN oportunidade.cliente_id%TYPE,
  p_flag_conflito           IN VARCHAR2,
  p_cliente_conflito_id     IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id              IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id      IN oportunidade.produto_cliente_id%TYPE,
  p_usuario_resp_id         IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id    IN oportunidade.unid_negocio_resp_id%TYPE,
  p_origem                  IN oportunidade.origem%TYPE,
  p_compl_origem            IN VARCHAR2,
  p_tipo_negocio            IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id        IN oportunidade.tipo_contrato_id%TYPE,
  p_usuario_comissionado_id IN oport_usuario.usuario_id%TYPE,
  p_nome_cenario            IN VARCHAR2,
  p_moeda                   IN VARCHAR2,
  p_valor_cotacao           IN VARCHAR2,
  p_data_cotacao            IN VARCHAR2,
  p_num_parcelas            IN VARCHAR2,
  p_coment_parcelas         IN VARCHAR2,
  p_flag_comissao           IN VARCHAR2,
  p_prazo_pagamento         IN VARCHAR2,
  p_cond_pagamento          IN VARCHAR2,
  p_int1_data               IN VARCHAR2,
  p_int1_usuario_id         IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato       IN VARCHAR2,
  p_int1_descricao          IN interacao.descricao%TYPE,
  p_perc_prob_fech          IN VARCHAR2,
  p_data_prov_fech          IN VARCHAR2,
  p_int2_data               IN VARCHAR2,
  p_int2_usuario_id         IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao          IN interacao.descricao%TYPE,
  p_flag_sem_def_valores    IN VARCHAR2,
  p_vetor_servico           IN VARCHAR2,
  p_vetor_valor             IN VARCHAR2,
  p_flag_sem_valor          IN VARCHAR2,
  p_oportunidade_id         OUT oportunidade.oportunidade_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_principal
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_nome                 IN oportunidade.nome%TYPE,
  p_cliente_id           IN oportunidade.cliente_id%TYPE,
  p_flag_conflito        IN VARCHAR2,
  p_cliente_conflito_id  IN oportunidade.cliente_conflito_id%TYPE,
  p_contato_id           IN oportunidade.contato_id%TYPE,
  p_produto_cliente_id   IN oportunidade.produto_cliente_id%TYPE,
  p_origem               IN oportunidade.origem%TYPE,
  p_compl_origem         IN VARCHAR2,
  p_tipo_negocio         IN oportunidade.tipo_negocio%TYPE,
  p_tipo_contrato_id     IN oportunidade.tipo_contrato_id%TYPE,
  p_usuario_resp_id      IN oportunidade.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN oportunidade.unid_negocio_resp_id%TYPE,
  p_flag_sem_def_valores IN VARCHAR2,
  p_vetor_servico        IN VARCHAR2,
  p_vetor_valor          IN VARCHAR2,
  p_flag_sem_valor       IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_comissionados
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id    IN oportunidade.oportunidade_id%TYPE,
  p_vetor_usuarios     IN VARCHAR2,
  p_vetor_comissionado IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_responsavel
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE interacao_andam_adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id     IN oportunidade.oportunidade_id%TYPE,
  p_int1_data           IN VARCHAR2,
  p_int1_usuario_id     IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato   IN VARCHAR2,
  p_int1_descricao      IN interacao.descricao%TYPE,
  p_perc_prob_fech      IN VARCHAR2,
  p_data_prov_fech      IN VARCHAR2,
  p_status_aux_oport_id IN oportunidade.status_aux_oport_id%TYPE,
  p_int2_data           IN VARCHAR2,
  p_int2_usuario_id     IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao      IN interacao.descricao%TYPE,
  p_interacao_id        OUT interacao.interacao_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE interacao_ganha_adicionar
 (
  p_usuario_sessao_id            IN NUMBER,
  p_empresa_id                   IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id              IN oportunidade.oportunidade_id%TYPE,
  p_cli_tipo_pessoa              IN VARCHAR2,
  p_cli_apelido                  IN VARCHAR2,
  p_cli_nome                     IN VARCHAR2,
  p_cli_produto                  IN VARCHAR2,
  p_cli_cnpj_cpf                 IN VARCHAR2,
  p_cli_endereco                 IN VARCHAR2,
  p_cli_num_ender                IN VARCHAR2,
  p_cli_compl_ender              IN VARCHAR2,
  p_cli_bairro                   IN VARCHAR2,
  p_cli_cep                      IN VARCHAR2,
  p_cli_cidade                   IN VARCHAR2,
  p_cli_uf                       IN VARCHAR2,
  p_cli_pais                     IN VARCHAR2,
  p_cli_email                    IN VARCHAR2,
  p_cli_ddd_telefone             IN VARCHAR2,
  p_cli_num_telefone             IN VARCHAR2,
  p_cli_nome_setor               IN VARCHAR2,
  p_int1_data                    IN VARCHAR2,
  p_int1_usuario_id              IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato            IN VARCHAR2,
  p_int1_descricao               IN interacao.descricao%TYPE,
  p_cenario_escolhido_id         IN cenario.cenario_id%TYPE,
  p_arquivo_prop_id              IN oportunidade.arquivo_prop_id%TYPE,
  p_arquivo_acei_id              IN oportunidade.arquivo_acei_id%TYPE,
  p_vetor_srv_cenario_servico_id IN VARCHAR2,
  p_vetor_srv_servico_id         IN VARCHAR2,
  p_vetor_srv_empresa_id         IN VARCHAR2,
  p_vetor_srv_emp_resp_id        IN VARCHAR2,
  p_vetor_srv_valor              IN VARCHAR2,
  p_vetor_srv_usu_resp_id        IN VARCHAR2,
  p_vetor_srv_uneg_resp_id       IN VARCHAR2,
  p_vetor_ctr_empresa_id         IN VARCHAR2,
  p_vetor_ctr_emp_resp_id        IN VARCHAR2,
  p_vetor_ctr_data_inicio        IN VARCHAR2,
  p_vetor_ctr_data_termino       IN VARCHAR2,
  p_vetor_ctr_flag_renovavel     IN VARCHAR2,
  p_vetor_ctr_flag_fisico        IN VARCHAR2,
  p_vetor_ender_empresas         IN VARCHAR2,
  p_vetor_ender_usuarios         IN VARCHAR2,
  p_vetor_ender_flag_resp        IN VARCHAR2,
  p_erro_cod                     OUT VARCHAR2,
  p_erro_msg                     OUT VARCHAR2
 );
 --
 PROCEDURE interacao_perda_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_int1_data         IN VARCHAR2,
  p_int1_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato IN VARCHAR2,
  p_int1_descricao    IN interacao.descricao%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_perda_para        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE interacao_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_interacao_id      IN interacao.interacao_id%TYPE,
  p_int1_data         IN VARCHAR2,
  p_int1_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int1_meio_contato IN VARCHAR2,
  p_int1_descricao    IN interacao.descricao%TYPE,
  p_perc_prob_fech    IN VARCHAR2,
  p_data_prov_fech    IN VARCHAR2,
  p_int2_data         IN VARCHAR2,
  p_int2_usuario_id   IN interacao.usuario_resp_id%TYPE,
  p_int2_descricao    IN interacao.descricao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE interacao_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_interacao_id      IN interacao.interacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE status_alterar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id     IN oportunidade.oportunidade_id%TYPE,
  p_status              IN oportunidade.status%TYPE,
  p_status_aux_oport_id IN status_aux_oport.status_aux_oport_id%TYPE,
  p_tipo_conc           IN VARCHAR2,
  p_motivo              IN VARCHAR2,
  p_complemento         IN VARCHAR2,
  p_perda_para          IN VARCHAR2,
  p_flag_commit         IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE desenderecar_usuario
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_usuario
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_coender      IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_automatico
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_manual
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cancelar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reabrir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE apagar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_oportun_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_oportunidade_id   IN arquivo_oportunidade.oportunidade_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_tipo_arq_oport    IN arquivo_oportunidade.tipo_arq_oport%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_oportun_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE visualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE pontencial_geracao_negocio_gerar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id      IN oportunidade.oportunidade_id%TYPE,
  p_flag_sem_def_valores IN VARCHAR2,
  p_vetor_servico        IN VARCHAR2,
  p_vetor_valor          IN VARCHAR2,
  p_flag_sem_valor       IN VARCHAR2,
  p_flag_commit          IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 FUNCTION data_termino_contrato_calcular
 (
  p_cenario_id       IN cenario.cenario_id%TYPE,
  p_vetor_servico_id IN VARCHAR2,
  p_data_inicio      IN VARCHAR2
 ) RETURN VARCHAR2;
 --
END; -- OPORTUNIDADE_PKG

/
