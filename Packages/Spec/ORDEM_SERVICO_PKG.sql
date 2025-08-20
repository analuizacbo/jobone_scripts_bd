--------------------------------------------------------
--  DDL for Package ORDEM_SERVICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ORDEM_SERVICO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN ordem_servico.job_id%TYPE,
  p_milestone_id           IN ordem_servico.milestone_id%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_descricao              IN ordem_servico.descricao%TYPE,
  p_data_solicitada        IN VARCHAR2,
  p_hora_solicitada        IN VARCHAR2,
  p_texto_os               IN ordem_servico.texto_os%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_tp_id            IN VARCHAR2,
  p_vetor_tp_compl         IN VARCHAR2,
  p_vetor_tp_desc          IN VARCHAR2,
  p_item_crono_id          IN item_crono.item_crono_id%TYPE,
  p_flag_com_estim         IN VARCHAR2,
  p_ordem_servico_id       OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_demais
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN ordem_servico.job_id%TYPE,
  p_repet_grupo            IN item_crono.repet_grupo%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_descricao              IN ordem_servico.descricao%TYPE,
  p_texto_os               IN ordem_servico.texto_os%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_tp_id            IN VARCHAR2,
  p_vetor_tp_compl         IN VARCHAR2,
  p_vetor_tp_desc          IN VARCHAR2,
  p_flag_com_estim         IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE basico_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_milestone_id      IN ordem_servico.milestone_id%TYPE,
  p_descricao         IN ordem_servico.descricao%TYPE,
  p_num_estim         IN VARCHAR2,
  p_data_entrada      IN VARCHAR2,
  p_hora_entrada      IN VARCHAR2,
  p_data_solicitada   IN VARCHAR2,
  p_hora_solicitada   IN VARCHAR2,
  p_data_interna      IN VARCHAR2,
  p_hora_interna      IN VARCHAR2,
  p_demanda           IN ordem_servico.demanda%TYPE,
  p_data_demanda      IN VARCHAR2,
  p_tamanho           IN ordem_servico.tamanho%TYPE,
  p_os_evento_id      IN ordem_servico.os_evento_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN CLOB,
  p_complex_refacao   IN os_evento.complex_refacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE corpo_atualizar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_financeiro_id      IN ordem_servico.tipo_financeiro_id%TYPE,
  p_servico_id              IN ordem_servico.servico_id%TYPE,
  p_texto_os                IN ordem_servico.texto_os%TYPE,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE copiar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_old_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_acao_executada         IN VARCHAR2,
  p_ordem_servico_new_id   OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE data_solic_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_solicitada   IN VARCHAR2,
  p_hora_solicitada   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE data_interna_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_interna      IN VARCHAR2,
  p_hora_interna      IN VARCHAR2,
  p_flag_atu_periodo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE tamanho_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tamanho           IN ordem_servico.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecados_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_enderecados  IN VARCHAR2,
  p_vetor_horas_planej IN VARCHAR2,
  p_vetor_sequencia    IN VARCHAR2,
  p_tipo_ender         IN VARCHAR2,
  p_flag_volta_status  IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE executores_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_hora_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_hora_termino      IN VARCHAR2,
  p_vetor_enderecados IN LONG,
  p_vetor_datas       IN LONG,
  p_vetor_horas       IN LONG,
  p_flag_volta_status IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fluxo_papel_desabilitar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_vetor_tipo_os_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fluxo_papel_habilitar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_vetor_tipo_os_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fluxo_aprov_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov        IN VARCHAR2,
  p_papel_id          OUT papel.papel_id%TYPE,
  p_seq_aprov         OUT os_fluxo_aprov.seq_aprov%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE acao_executar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_flag_commit            IN VARCHAR2,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_cod_acao_os            IN VARCHAR2,
  p_evento_motivo_id       IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario             IN VARCHAR2,
  p_complex_refacao        IN os_evento.complex_refacao%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_vetor_os_link_id       IN VARCHAR2,
  p_vetor_usuario_id       IN VARCHAR2,
  p_vetor_tipo_notifica    IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE concluir_cancelar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE concluir_em_massa
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_data_de           IN VARCHAR2,
  p_data_ate          IN VARCHAR2,
  p_status            IN VARCHAR2,
  p_tipo_os_id        IN tipo_os.tipo_os_id%TYPE,
  p_tipo_refacao      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE usuario_confirmacao_atividade
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_vetor_ordem_servico IN VARCHAR2,
  p_vetor_status_aux    IN VARCHAR2,
  p_vetor_motivo        IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE usuario_refacao_gravar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE terminar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE retomar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE refazer_em_nova
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_evento_motivo_id       IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario             IN CLOB,
  p_complex_refacao        IN os_evento.complex_refacao%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_vetor_os_link_id       IN VARCHAR2,
  p_ordem_servico_new_id   OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE concluir_automatico;
 --
 PROCEDURE custo_estimar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_custo_estim       IN VARCHAR2,
  p_dias_estim        IN VARCHAR2,
  p_obs_estim         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE estimativa_aprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_estim_id       IN ordem_servico.os_estim_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE estimativa_recusar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_estim_id       IN ordem_servico.os_estim_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN CLOB,
  p_complex_refacao   IN os_evento.complex_refacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE lido_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nao_lido_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE metadados_validar
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nota_aval_registrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_ender        IN VARCHAR2,
  p_nota_aval         IN VARCHAR2,
  p_comentario        IN CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_ordem_servico_id  IN os_horas.ordem_servico_id%TYPE,
  p_usuario_id        IN os_horas.usuario_id%TYPE,
  p_cargo_id          IN os_horas.cargo_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_os_horas_id       IN os_horas.os_horas_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_horas_id       IN os_horas.os_horas_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN NUMBER,
  p_arquivo_id          IN arquivo.arquivo_id%TYPE,
  p_volume_id           IN arquivo.volume_id%TYPE,
  p_ordem_servico_id    IN arquivo_os.ordem_servico_id%TYPE,
  p_descricao           IN arquivo.descricao%TYPE,
  p_nome_original       IN arquivo.nome_original%TYPE,
  p_nome_fisico         IN arquivo.nome_fisico%TYPE,
  p_mime_type           IN arquivo.mime_type%TYPE,
  p_tamanho             IN arquivo.tamanho%TYPE,
  p_palavras_chave      IN VARCHAR2,
  p_thumb_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb_nome_original IN arquivo.nome_original%TYPE,
  p_thumb_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_os         IN arquivo_os.tipo_arq_os%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_ordem_servico_id  IN arquivo_os.ordem_servico_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_ordem_servico_id  IN arquivo_os.ordem_servico_id%TYPE,
  p_flag_remover      OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_mover
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_novo_tipo_arq_os  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE os_link_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN os_link.tipo_link%TYPE,
  p_os_link_id        OUT os_link.os_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE os_link_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_link_id        IN os_link.os_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE afazer_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_afazer.ordem_servico_id%TYPE,
  p_usuario_resp_id   IN os_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_os_afazer_id      OUT os_afazer.os_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE afazer_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_usuario_resp_id   IN os_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE afazer_feito_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_flag_feito        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE afazer_reordenar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN NUMBER,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_os_afazer_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE afazer_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE os_negociacao_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_data_sugerida     IN VARCHAR2,
  p_hora_sugerida     IN VARCHAR2,
  p_comentario        IN CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE os_negociacao_aceitar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_data_sugerida     IN VARCHAR2,
  p_hora_sugerida     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE tipos_produtos_adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE tipos_produtos_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_adicionar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN os_tipo_produto.ordem_servico_id%TYPE,
  p_tipo_produto_id         IN job_tipo_produto.tipo_produto_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_descricao               IN CLOB,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_atualizar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN os_tipo_produto.ordem_servico_id%TYPE,
  p_job_tipo_produto_id     IN job_tipo_produto.job_tipo_produto_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_descricao               IN CLOB,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_excluir
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN os_tipo_produto.ordem_servico_id%TYPE,
  p_job_tipo_produto_id IN os_tipo_produto.job_tipo_produto_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_refacao_marcar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_num_refacao            IN VARCHAR2,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_refacao_desmarcar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_num_refacao            IN VARCHAR2,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE fator_tempo_calcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE dias_calcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN os_refacao.ordem_servico_id%TYPE,
  p_num_refacao       IN os_refacao.num_refacao%TYPE,
  p_flag_estim        IN os_refacao.flag_estim%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprovacao_autom_processar;
 --
 PROCEDURE aval_cliente_registrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_nota_aval_cli     IN VARCHAR2,
  p_coment_aval_cli   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprov_cliente_registrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_flag_com_aval     IN VARCHAR2,
  p_nota_aval_cli     IN VARCHAR2,
  p_coment_aval_cli   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE duplicar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_os_nova_id        OUT ordem_servico.ordem_servico_id%TYPE,
  p_os_nova_numero    OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
 FUNCTION atuacao_usuario_retornar
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2;
 --
 FUNCTION enderecados_retornar
 (
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_ender         IN VARCHAR2,
  p_flag_marca_inativo IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 FUNCTION com_usuarios_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION desc_evento_retornar
 (
  p_cod_acao    IN os_transicao.cod_acao%TYPE,
  p_status_de   IN os_transicao.status_de%TYPE,
  p_status_para IN os_transicao.status_para%TYPE
 ) RETURN VARCHAR2;
 --
 FUNCTION dias_depend_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION tempo_exec_prev_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION tempo_exec_gasto_retornar
 (
  p_ordem_servico_id IN os_tipo_produto.ordem_servico_id%TYPE,
  p_tipo_produto_id  IN job_tipo_produto.tipo_produto_id%TYPE
 ) RETURN NUMBER;
 --
 FUNCTION descricao_retornar(p_ordem_servico_id IN os_tipo_produto.ordem_servico_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION ultima_os_retornar(p_job_tipo_produto_id IN job_tipo_produto.job_tipo_produto_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION ultimo_evento_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION horas_retornar
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_papel_id         IN papel.papel_id%TYPE,
  p_nivel            IN usuario_cargo.nivel%TYPE,
  p_tipo             IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION data_retornar
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo             IN VARCHAR2
 ) RETURN DATE;
 --
 FUNCTION data_status_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN DATE;
 --
 FUNCTION data_apont_retornar
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo              IN VARCHAR2
 ) RETURN DATE;
 --
 FUNCTION numero_formatar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION nome_retornar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION numero_formatar2(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION faixa_aprov_verificar
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION faixa_aprov_id_retornar
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov       IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION fluxo_seq_ok_verificar
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov       IN VARCHAR2
 ) RETURN INTEGER;
 --
 FUNCTION papel_priv_verificar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo_priv       IN privilegio.codigo%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION preenchimento_ok_verificar(p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE)
  RETURN INTEGER;
 --
END; -- ORDEM_SERVICO_PKG

/
