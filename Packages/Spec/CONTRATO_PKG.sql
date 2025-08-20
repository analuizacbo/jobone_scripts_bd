--------------------------------------------------------
--  DDL for Package CONTRATO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CONTRATO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_ori_id   IN contrato.contrato_id%TYPE,
  p_tipo_contrato_id  IN contrato.tipo_contrato_id%TYPE,
  p_cod_ext_contrato  IN contrato.cod_ext_contrato%TYPE,
  p_nome              IN contrato.nome%TYPE,
  p_contratante_id    IN contrato.contratante_id%TYPE,
  p_contato_id        IN contrato.contato_id%TYPE,
  p_emp_resp_id       IN contrato.emp_resp_id%TYPE,
  p_data_assinatura   IN VARCHAR2,
  p_data_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_flag_renovavel    IN VARCHAR2,
  p_objeto            IN contrato.objeto%TYPE,
  p_ordem_compra      IN contrato.ordem_compra%TYPE,
  p_cod_ext_ordem     IN contrato.cod_ext_ordem%TYPE,
  p_contrato_id       OUT contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_simples
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN contrato.empresa_id%TYPE,
  p_tipo_contrato_id      IN contrato.tipo_contrato_id%TYPE,
  p_emp_resp_id           IN contrato.emp_resp_id%TYPE,
  p_nome                  IN contrato.nome%TYPE,
  p_cli_flag_pessoa_jur   IN VARCHAR2,
  p_cli_flag_exterior     IN VARCHAR2,
  p_cli_flag_sem_docum    IN VARCHAR2,
  p_cli_apelido           IN VARCHAR2,
  p_cli_nome              IN VARCHAR2,
  p_cli_cnpj              IN VARCHAR2,
  p_cli_cpf               IN VARCHAR2,
  p_cli_endereco          IN VARCHAR2,
  p_cli_num_ender         IN VARCHAR2,
  p_cli_compl_ender       IN VARCHAR2,
  p_cli_bairro            IN VARCHAR2,
  p_cli_cep               IN VARCHAR2,
  p_cli_cidade            IN VARCHAR2,
  p_cli_uf                IN VARCHAR2,
  p_cli_pais              IN VARCHAR2,
  p_cli_email             IN VARCHAR2,
  p_cli_ddd_telefone      IN VARCHAR2,
  p_cli_num_telefone      IN VARCHAR2,
  p_cli_nome_setor        IN VARCHAR2,
  p_data_inicio           IN VARCHAR2,
  p_data_termino          IN VARCHAR2,
  p_flag_renovavel        IN VARCHAR2,
  p_flag_ctr_fisico       IN VARCHAR2,
  p_vetor_ender_empresas  IN VARCHAR2,
  p_vetor_ender_usuarios  IN VARCHAR2,
  p_vetor_ender_flag_resp IN VARCHAR2,
  p_contrato_id           OUT contrato.contrato_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_id            IN contrato.contrato_id%TYPE,
  p_tipo_contrato_id       IN contrato.tipo_contrato_id%TYPE,
  p_cod_ext_contrato       IN contrato.cod_ext_contrato%TYPE,
  p_nome                   IN contrato.nome%TYPE,
  p_contratante_id         IN contrato.contratante_id%TYPE,
  p_contato_id             IN contrato.contato_id%TYPE,
  p_emp_resp_id            IN contrato.emp_resp_id%TYPE,
  p_data_assinatura        IN VARCHAR2,
  p_data_inicio            IN VARCHAR2,
  p_data_termino           IN VARCHAR2,
  p_flag_repetir           IN VARCHAR2,
  p_flag_renovavel         IN VARCHAR2,
  p_flag_ctr_fisico        IN VARCHAR2,
  p_objeto                 IN contrato.objeto%TYPE,
  p_ordem_compra           IN contrato.ordem_compra%TYPE,
  p_cod_ext_ordem          IN contrato.cod_ext_ordem%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_contato_fatur_id       IN contrato.contato_fatur_id%TYPE,
  p_flag_pago_cliente      IN VARCHAR2,
  p_flag_bloq_negoc        IN VARCHAR2,
  p_flag_bv_fornec         IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_emp_faturar_por_id     IN contrato.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_vigencia
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_flag_repetir      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_responsavel
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE desconto_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_perc_desc         IN VARCHAR2,
  p_motivo_desc       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE assinado_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_assinatura   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE assinado_desmarcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE apagar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE concluir_automatico;
 --
 PROCEDURE enderecar_automatico
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_usuario
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_usuario_id        IN contrato_usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE status_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_status_new        IN contrato.status%TYPE,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_id         IN contrato_horas.contrato_id%TYPE,
  p_tipo_formulario     IN VARCHAR2,
  p_usuario_id          IN contrato_horas.usuario_id%TYPE,
  p_cargo_id            IN contrato_horas.cargo_id%TYPE,
  p_nivel               IN contrato_horas.nivel%TYPE,
  p_contrato_servico_id IN contrato_horas.contrato_servico_id%TYPE,
  p_descricao           IN VARCHAR2,
  p_vetor_mes_ano_de    IN VARCHAR2,
  p_vetor_mes_ano_ate   IN VARCHAR2,
  p_vetor_horas_planej  IN VARCHAR2,
  p_vetor_venda_hora    IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE horas_desc_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_planej_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_venda_valor_total OUT NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_fator_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_horas_id  IN contrato_horas.contrato_horas_id%TYPE,
  p_venda_fator_ajuste IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE horas_venda_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_venda_hora_rev    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_ajustar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_id        IN contrato.contrato_id%TYPE,
  p_venda_fator_ajuste IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE horas_servico_atualizar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_horas_id   IN contrato_horas.contrato_horas_id%TYPE,
  p_contrato_servico_id IN contrato_horas.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE horas_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_linha_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato_horas.contrato_id%TYPE,
  p_usuario_id        IN contrato_horas.usuario_id%TYPE,
  p_cargo_id          IN contrato_horas.cargo_id%TYPE,
  p_nivel             IN contrato_horas.nivel%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_usu_adicionar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN contrato.empresa_id%TYPE,
  p_contrato_id             IN contrato.contrato_id%TYPE,
  p_vetor_contrato_horas_id IN VARCHAR2,
  p_vetor_usuario_id        IN VARCHAR2,
  p_vetor_horas_aloc        IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE horas_usu_atualizar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN contrato.empresa_id%TYPE,
  p_contrato_horas_usu_id IN contrato_horas_usu.contrato_horas_usu_id%TYPE,
  p_horas_aloc            IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE horas_usu_excluir
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN contrato.empresa_id%TYPE,
  p_contrato_id             IN contrato.contrato_id%TYPE,
  p_usuario_id              IN contrato_horas_usu.usuario_id%TYPE,
  p_vetor_contrato_horas_id IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE valores_sugeridos_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_horas_id IN contrato_horas.contrato_horas_id%TYPE,
  p_custo_hora_pdr    IN VARCHAR2,
  p_venda_hora_pdr    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE servico_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_id        IN contrato_servico.contrato_id%TYPE,
  p_servico_id         IN contrato_servico.servico_id%TYPE,
  p_emp_faturar_por_id IN contrato.emp_faturar_por_id%TYPE,
  p_data_inicio        IN VARCHAR2,
  p_data_termino       IN VARCHAR2,
  p_descricao          IN VARCHAR2,
  p_cod_externo        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE servico_atualizar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_servico_id          IN contrato_servico.servico_id%TYPE,
  p_emp_faturar_por_id  IN contrato.emp_faturar_por_id%TYPE,
  p_data_inicio         IN VARCHAR2,
  p_data_termino        IN VARCHAR2,
  p_descricao           IN VARCHAR2,
  p_cod_externo         IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE servico_excluir
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE servico_integrar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE servico_valor_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN contrato.empresa_id%TYPE,
  p_contrato_servico_id  IN contrato_servico.contrato_servico_id%TYPE,
  p_emp_resp_id          IN contrato_serv_valor.emp_resp_id%TYPE,
  p_valor_servico        IN VARCHAR2,
  p_usuario_resp_id      IN contrato_serv_valor.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id IN contrato_serv_valor.unid_negocio_resp_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE servico_valor_atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_serv_valor_id IN contrato_serv_valor.contrato_serv_valor_id%TYPE,
  p_emp_resp_id            IN contrato_serv_valor.emp_resp_id%TYPE,
  p_valor_servico          IN VARCHAR2,
  p_usuario_resp_id        IN contrato_serv_valor.usuario_resp_id%TYPE,
  p_unid_negocio_resp_id   IN contrato_serv_valor.unid_negocio_resp_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE servico_valor_excluir
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN contrato.empresa_id%TYPE,
  p_contrato_serv_valor_id IN contrato_serv_valor.contrato_serv_valor_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE parcelas_gerar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_contrato_id         IN contrato_servico.contrato_id%TYPE,
  p_contrato_servico_id IN contrato_servico.contrato_servico_id%TYPE,
  p_num_parcelas        IN VARCHAR2,
  p_data_prim_parcela   IN VARCHAR2,
  p_valor_parcela       IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE parcela_alterar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_data_vencim         IN VARCHAR2,
  p_valor_parcela       IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE parcela_excluir
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN contrato.empresa_id%TYPE,
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE parcelamento_terminar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE parcelamento_revisar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
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
  p_contrato_id       IN arquivo_contrato.contrato_id%TYPE,
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
 PROCEDURE xml_gerar
 (
  p_contrato_id IN contrato.contrato_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 );
 --
 FUNCTION numero_formatar(p_contrato_id IN contrato.contrato_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION horas_do_usuario_retornar
 (
  p_empresa_id IN contrato.empresa_id%TYPE,
  p_usuario_id IN contrato.contrato_id%TYPE,
  p_tipo       IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_retornar
 (
  p_contrato_id IN contrato.contrato_id%TYPE,
  p_tipo_valor  IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_parcela_retornar
 (
  p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE,
  p_tipo_valor          IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION status_parcela_retornar(p_parcela_contrato_id IN parcela_contrato.parcela_contrato_id%TYPE)
  RETURN VARCHAR2;
 --
END; -- CONTRATO_PKG


/
