--------------------------------------------------------
--  DDL for Package JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "JOB_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_cliente_id         IN job.cliente_id%TYPE,
  p_emp_resp_id        IN job.emp_resp_id%TYPE,
  p_tipo_job_id        IN job.tipo_job_id%TYPE,
  p_tipo_financeiro_id IN job.tipo_financeiro_id%TYPE,
  p_contrato_id        IN job.contrato_id%TYPE,
  p_campanha_id        IN job.campanha_id%TYPE,
  p_numero_job         IN VARCHAR2,
  p_cod_ext_job        IN VARCHAR2,
  p_nome               IN job.nome%TYPE,
  p_descricao          IN LONG,
  p_complex_job        IN VARCHAR2,
  p_flag_commit        IN VARCHAR2,
  p_produto_cliente_id IN VARCHAR2,
  p_data_prev_ini      IN VARCHAR2,
  p_data_prev_fim      IN VARCHAR2,
  p_job_id             OUT job.job_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE consistir
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_numero_job               IN VARCHAR2,
  p_cod_ext_job              IN VARCHAR2,
  p_nome                     IN job.nome%TYPE,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_flag_obriga_desc_horas   IN VARCHAR2,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_mod_crono_id             IN mod_crono.mod_crono_id%TYPE,
  p_data_crono_base          IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_flag_concorrencia        IN VARCHAR2,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_tipo_chamada             IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_wizard
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_numero_job               IN VARCHAR2,
  p_cod_ext_job              IN VARCHAR2,
  p_nome                     IN job.nome%TYPE,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_flag_obriga_desc_horas   IN VARCHAR2,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_mod_crono_id             IN mod_crono.mod_crono_id%TYPE,
  p_data_crono_base          IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_flag_concorrencia        IN VARCHAR2,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_requisicao_cliente       IN briefing.requisicao_cliente%TYPE,
  p_vetor_area_id            IN VARCHAR2,
  p_vetor_atributo_id        IN VARCHAR2,
  p_vetor_atributo_valor     IN CLOB,
  p_vetor_dicion_emp_id      IN VARCHAR2,
  p_vetor_dicion_emp_val_id  IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_flag_commit              IN VARCHAR2,
  p_tipo_chamada             IN VARCHAR2,
  p_job_id                   OUT job.job_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_do_cliente
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN job.empresa_id%TYPE,
  p_cliente_id           IN job.cliente_id%TYPE,
  p_nome                 IN job.nome%TYPE,
  p_produto_cliente_id   IN job.produto_cliente_id%TYPE,
  p_nome_produto_cliente IN VARCHAR2,
  p_descricao_cliente    IN CLOB,
  p_contrato_id          IN job.contrato_id%TYPE,
  p_budget               IN VARCHAR2,
  p_flag_budget_nd       IN VARCHAR2,
  p_job_id               OUT job.job_id%TYPE,
  p_briefing_id          OUT briefing.briefing_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_principal
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_job_id                   IN job.job_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_nome                     IN job.nome%TYPE,
  p_cod_ext_job              IN VARCHAR2,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_flag_alt_data_estim      IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_concorrencia
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_flag_concorrencia IN job.flag_concorrencia%TYPE,
  p_contra_quem       IN job.contra_quem%TYPE,
  p_flag_conc_perdida IN job.flag_conc_perdida%TYPE,
  p_perdida_para      IN job.perdida_para%TYPE,
  p_motivo_cancel     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_financeiro
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN job.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_contato_fatur_id       IN job.contato_fatur_id%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_flag_pago_cliente      IN job.flag_pago_cliente%TYPE,
  p_flag_bloq_negoc        IN job.flag_bloq_negoc%TYPE,
  p_flag_bv_fornec         IN job.flag_bv_fornec%TYPE,
  p_perc_bv                IN VARCHAR2,
  p_emp_faturar_por_id     IN job.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_comissionados
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_usuarios     IN VARCHAR2,
  p_vetor_comissionado IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_responsavel
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_periodo_apont
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN job.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_data_apont_ini         IN VARCHAR2,
  p_data_apont_fim         IN VARCHAR2,
  p_flag_obriga_desc_horas IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_job_id            IN arquivo_job.job_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE receita_contrato_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_valor_alocado     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE receita_contrato_excluir
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_receita_ctr_id IN job_receita_ctr.job_receita_ctr_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE valor_ajuste_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_data              IN VARCHAR2,
  p_descricao         IN ajuste_job.descricao%TYPE,
  p_valor_ajuste      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE valor_ajuste_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_ajuste_job_id     IN ajuste_job.ajuste_job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE checkin_fechar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE faturamento_fechar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE status_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_status            IN job.status%TYPE,
  p_status_aux_job_id IN status_aux_job.status_aux_job_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE caminho_arq_alterar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN job.empresa_id%TYPE,
  p_job_id              IN job.job_id%TYPE,
  p_caminho_arq_externo IN job.caminho_arq_externo%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE status_tratar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_tipo_status       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reabrir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE concluir_automatico;
 --
 PROCEDURE concluir_em_massa
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_data_de           IN VARCHAR2,
  p_data_ate          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE resp_int_tratar
 (
  p_job_id     IN job.job_id%TYPE,
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE desenderecar_usuario
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
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
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
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
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_manual
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_solidario
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_todos_usuarios
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE task_gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_prioridade        IN task.prioridade%TYPE,
  p_vetor_papel_id    IN LONG,
  p_obs               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE apagar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE visualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE lido_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nao_lido_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_tipo              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE prox_numero_retornar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_cliente_id         IN job.cliente_id%TYPE,
  p_tipo_financeiro_id IN job.tipo_financeiro_id%TYPE,
  p_numero_job         OUT job.numero%TYPE,
  p_tipo_num_job       OUT job.tipo_num_job%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE xml_gerar
 (
  p_job_id   IN job.job_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 --
 FUNCTION usuarios_retornar
 (
  p_job_id   IN job.job_id%TYPE,
  p_papel_id IN papel.papel_id%TYPE
 ) RETURN VARCHAR2;
 --
 --
 FUNCTION menor_data_aprov_retornar
 (
  p_job_id    IN job.job_id%TYPE,
  p_tipo_item IN VARCHAR2
 ) RETURN DATE;
 --
 --
 FUNCTION nome_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION valor_retornar
 (
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_custo_retornar
 (
  p_job_id       IN job.job_id%TYPE,
  p_tipo_item    IN VARCHAR2,
  p_status_orcam IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_realizado_retornar
 (
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_abat_retornar
 (
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_cred_retornar
 (
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_outras_receitas_retornar
 (
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_economia_retornar
 (
  p_job_id       IN job.job_id%TYPE,
  p_tipo_item    IN VARCHAR2,
  p_status_orcam IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_custo_horas_retornar
 (
  p_job_id IN job.job_id%TYPE,
  p_tipo   IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION status_checkin_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION status_fatur_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION data_fech_fatur_retornar(p_job_id IN job.job_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION horas_retornar
 (
  p_job_id IN job.job_id%TYPE,
  p_nivel  IN usuario_cargo.nivel%TYPE,
  p_tipo   IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION usuario_solic_retornar(p_job_id IN job.job_id%TYPE) RETURN NUMBER;
 --
 --
 FUNCTION sla_data_inicio_job_retornar(p_job_id IN job.job_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION sla_data_inicio_retornar(p_job_id IN job.job_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION sla_data_inicio_ori_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION sla_data_limite_retornar(p_job_id IN job.job_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION sla_data_limite_ori_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION sla_data_termino_retornar(p_job_id IN job.job_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION sla_job_no_prazo_retornar(p_job_id IN job.job_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION sla_num_dias_retornar(p_job_id IN job.job_id%TYPE) RETURN INT;
 --
--
END; -- JOB_PKG

/
