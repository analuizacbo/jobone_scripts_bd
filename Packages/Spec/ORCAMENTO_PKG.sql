--------------------------------------------------------
--  DDL for Package ORCAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ORCAMENTO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN orcamento.job_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_usuario_resp_id   IN NUMBER,
  p_orcamento_id      OUT orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_demais
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN orcamento.job_id%TYPE,
  p_repet_grupo       IN item_crono.repet_grupo%TYPE,
  p_descricao         IN VARCHAR2,
  p_usuario_resp_id   IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_orcamento_id           IN orcamento.orcamento_id%TYPE,
  p_contato_fatur_id       IN orcamento.contato_fatur_id%TYPE,
  p_emp_faturar_por_id     IN orcamento.emp_faturar_por_id%TYPE,
  p_tipo_job_id            IN orcamento.tipo_job_id%TYPE,
  p_servico_id             IN orcamento.servico_id%TYPE,
  p_tipo_financeiro_id     IN orcamento.tipo_financeiro_id%TYPE,
  p_ordem_compra           IN VARCHAR2,
  p_cod_externo            IN VARCHAR2,
  p_descricao              IN VARCHAR2,
  p_data_prev_ini          IN VARCHAR2,
  p_data_prev_fim          IN VARCHAR2,
  p_meta_valor_min         IN VARCHAR2,
  p_meta_valor_max         IN VARCHAR2,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_uf_servico             IN VARCHAR2,
  p_municipio_servico      IN VARCHAR2,
  p_obs_checkin            IN VARCHAR2,
  p_obs_fatur              IN VARCHAR2,
  p_flag_pago_cliente      IN orcamento.flag_pago_cliente%TYPE,
  p_data_prev_fec_check    IN VARCHAR2,
  p_flag_so_descricao      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE desc_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ordem_compra_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_ordem_compra      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE autor_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_usuario_autor_id  IN orcamento.usuario_autor_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE copiar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job_de        IN VARCHAR2,
  p_num_orcam_de      IN VARCHAR2,
  p_job_para_id       IN job.job_id%TYPE,
  p_orcam_para_id     OUT orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE desarquivar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE terminar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE retomar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_compl_reprov      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE revisar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE revisar_especial
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcamento     IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE honorario_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcamento     IN VARCHAR2,
  p_perc_honor        IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_transferir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_num_job           IN VARCHAR2,
  p_num_orcam_de      IN VARCHAR2,
  p_num_item          IN VARCHAR2,
  p_num_orcam_para    IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE checkin_encerrar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_orcamento_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE faturamento_encerrar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_orcamento_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE task_gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_objeto_id         IN NUMBER,
  p_tipo_task         IN VARCHAR2,
  p_prioridade        IN task.prioridade%TYPE,
  p_vetor_papel_id    IN LONG,
  p_obs               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE grupo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo_old         IN item.grupo%TYPE,
  p_grupo_new         IN item.grupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE subgrupo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo_old      IN item.subgrupo%TYPE,
  p_subgrupo_new      IN item.subgrupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE grupo_mover
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE subgrupo_mover
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo          IN item.subgrupo%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_mover
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE num_seq_recalcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE totais_gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE totais_recalcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_usuario
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_orcamento_id      IN orcam_usuario.orcamento_id%TYPE,
  p_usuario_id        IN orcam_usuario.usuario_id%TYPE,
  p_atuacao           IN orcam_usuario.atuacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_orcamento_id      IN arquivo_orcamento.orcamento_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_tipo_arq_orcam    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_orcamento_id      IN arquivo_orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE saldos_acessorios_recalcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_orcamento_id      IN orcamento.orcamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_xml          OUT CLOB,
  p_erro_cod     OUT VARCHAR2,
  p_erro_msg     OUT VARCHAR2
 );
 --
 --
 FUNCTION liberado_fatur_verificar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN INTEGER;
 --
 --
 FUNCTION numero_formatar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION numero_formatar2(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN VARCHAR2;
 --
 --
 FUNCTION qtd_itens_retornar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN INTEGER;
 --
 --
 FUNCTION valor_retornar
 (
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_outras_receitas_retornar
 (
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_abat_retornar
 (
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_cred_retornar
 (
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_fornec_apagar_retornar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN NUMBER;
 --
 --
 FUNCTION valor_checkin_pend_retornar
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_item    IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_geral_pend_retornar
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_item    IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_realizado_retornar
 (
  p_orcamento_id  IN orcamento.orcamento_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_tipo_item     IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION valor_rentab_retornar
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_calculo IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION parcelado_verificar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN INTEGER;
 --
 --
 FUNCTION carta_acordo_ok_verificar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN INTEGER;
 --
END; -- ORCAMENTO_PKG

/
