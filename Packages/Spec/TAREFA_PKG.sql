--------------------------------------------------------
--  DDL for Package TAREFA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TAREFA_PKG" IS

 --
 PROCEDURE adicionar_temp
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN tarefa.job_id%TYPE,
  p_flag_desc_usuario  IN VARCHAR2,
  p_num_max_itens      IN VARCHAR2,
  p_num_max_dias_prazo IN VARCHAR2,
  p_flag_obriga_item   IN VARCHAR2,
  p_descricao          IN VARCHAR2,
  p_tarefa_id          OUT tarefa.tarefa_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );

 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_tarefa_temp_id      IN tarefa.tarefa_id%TYPE,
  p_job_id              IN job.job_id%TYPE,
  p_tipo_tarefa_id      IN tarefa.tipo_tarefa_id%TYPE,
  p_descricao           IN VARCHAR2,
  p_detalhes            IN tarefa.detalhes%TYPE,
  p_flag_volta_exec     IN VARCHAR2,
  p_data_inicio         IN VARCHAR2,
  p_hora_inicio         IN VARCHAR2,
  p_data_termino        IN VARCHAR2,
  p_hora_termino        IN VARCHAR2,
  p_vetor_usuario_id    IN VARCHAR2,
  p_vetor_datas         IN VARCHAR2,
  p_vetor_horas         IN VARCHAR2,
  p_item_crono_id       IN item_crono.item_crono_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_repet_a_cada        IN VARCHAR2,
  p_frequencia_id       IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id IN VARCHAR2,
  p_repet_term_tipo     IN VARCHAR2,
  p_data_term_repet     IN VARCHAR2,
  p_repet_term_ocor     IN VARCHAR2,
  p_tarefa_id           OUT tarefa.tarefa_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );

 --
 PROCEDURE adicionar_demais
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN job.job_id%TYPE,
  p_repet_grupo       IN item_crono.repet_grupo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE atualizar_job
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_job_id            IN tarefa.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE atualizar_principal
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_detalhes          IN tarefa.detalhes%TYPE,
  p_flag_volta_exec   IN VARCHAR2,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE atualizar_estimativa
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_hora_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_hora_termino      IN VARCHAR2,
  p_vetor_usuario_id  IN VARCHAR2,
  p_vetor_datas       IN VARCHAR2,
  p_vetor_horas       IN VARCHAR2,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE usuario_repet_processar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tipo_alteracao      IN VARCHAR2,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_cod_acao_usu        IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );

 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE terminar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );

 --
 PROCEDURE retomar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );

 --
 PROCEDURE acao_executar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_cod_acao_tarefa   IN VARCHAR2,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE cancelar_demais
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN VARCHAR2,
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
  p_tarefa_id           IN arquivo_tarefa.tarefa_id%TYPE,
  p_descricao           IN arquivo.descricao%TYPE,
  p_nome_original       IN arquivo.nome_original%TYPE,
  p_nome_fisico         IN arquivo.nome_fisico%TYPE,
  p_mime_type           IN arquivo.mime_type%TYPE,
  p_tamanho             IN arquivo.tamanho%TYPE,
  p_thumb_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb_nome_original IN arquivo.nome_original%TYPE,
  p_thumb_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_tarefa     IN arquivo_tarefa.tipo_arq_tarefa%TYPE,
  p_palavras_chave      IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
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
 PROCEDURE link_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_id         IN tarefa_link.tarefa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN tarefa_link.tipo_link%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_tarefa_link_id    OUT tarefa_link.tarefa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE link_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_link_id    IN tarefa_link.tarefa_link_id%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE afazer_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_id         IN tarefa_afazer.tarefa_id%TYPE,
  p_usuario_resp_id   IN tarefa_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_tarefa_afazer_id  OUT tarefa_afazer.tarefa_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE afazer_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_usuario_resp_id   IN tarefa_afazer.usuario_resp_id%TYPE,
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
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_flag_feito        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE afazer_reordenar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN NUMBER,
  p_tarefa_id              IN tarefa.tarefa_id%TYPE,
  p_vetor_tarefa_afazer_id IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );

 --
 PROCEDURE afazer_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );

 --
 PROCEDURE tipo_produto_adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_id              IN tarefa_tipo_produto.tarefa_id%TYPE,
  p_tipo_produto_id        IN job_tipo_produto.tipo_produto_id%TYPE,
  p_complemento            IN VARCHAR2,
  p_descricao              IN CLOB,
  p_vetor_atributo_id      IN VARCHAR2,
  p_vetor_atributo_valor   IN CLOB,
  p_tipo_alteracao         IN VARCHAR2,
  p_tarefa_tipo_produto_id OUT tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );

 --
 PROCEDURE tipo_produto_atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_tipo_produto_id IN tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_complemento            IN VARCHAR2,
  p_descricao              IN CLOB,
  p_vetor_atributo_id      IN VARCHAR2,
  p_vetor_atributo_valor   IN CLOB,
  p_tipo_alteracao         IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );

 --
 PROCEDURE tipo_produto_excluir
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_tipo_produto_id IN tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_tipo_alteracao         IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );

 --
 FUNCTION numero_formatar(p_tarefa_id IN tarefa.tarefa_id%TYPE) RETURN VARCHAR2;

 --
 FUNCTION enderecados_retornar(p_tarefa_id IN tarefa.tarefa_id%TYPE) RETURN VARCHAR2;

 --
 FUNCTION priv_no_grupo_verificar
 (
  p_usuario_sessao_id IN NUMBER,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_tipo_verif        IN VARCHAR2
 ) RETURN INTEGER;

 --
 FUNCTION ultimo_evento_retornar(p_tarefa_id IN tarefa.tarefa_id%TYPE) RETURN NUMBER;

 --
 PROCEDURE xml_gerar
 (
  p_tarefa_id       IN tarefa.tarefa_id%TYPE,
  p_flag_com_evento IN VARCHAR2,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );

--
END; -- TAREFA_PKG

/
