--------------------------------------------------------
--  DDL for Package CARTA_ACORDO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CARTA_ACORDO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_fornecedor_id          IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id             IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id     IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec         IN carta_acordo.contato_fornec%TYPE,
  p_jus_fornec_naohmlg     IN VARCHAR2,
  p_desc_item              IN VARCHAR2,
  p_valor_credito          IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_motivo_atu_bv          IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_motivo_atu_imp         IN VARCHAR2,
  p_tipo_fatur_bv          IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_condicao_pagto_id      IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto             IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id        IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia        IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta          IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta         IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar     IN VARCHAR2,
  p_instr_especiais        IN VARCHAR2,
  p_entre_data_prototipo   IN VARCHAR2,
  p_entre_data_produto     IN VARCHAR2,
  p_entre_local            IN VARCHAR2,
  p_monta_hora_ini         IN VARCHAR2,
  p_monta_data_ini         IN VARCHAR2,
  p_monta_hora_fim         IN VARCHAR2,
  p_monta_data_fim         IN VARCHAR2,
  p_pserv_hora_ini         IN VARCHAR2,
  p_pserv_data_ini         IN VARCHAR2,
  p_pserv_hora_fim         IN VARCHAR2,
  p_pserv_data_fim         IN VARCHAR2,
  p_desmo_hora_ini         IN VARCHAR2,
  p_desmo_data_ini         IN VARCHAR2,
  p_desmo_hora_fim         IN VARCHAR2,
  p_desmo_data_fim         IN VARCHAR2,
  p_event_desc             IN VARCHAR2,
  p_event_local            IN VARCHAR2,
  p_event_hora_ini         IN VARCHAR2,
  p_event_data_ini         IN VARCHAR2,
  p_event_hora_fim         IN VARCHAR2,
  p_event_data_fim         IN VARCHAR2,
  p_produtor_id            IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao     IN VARCHAR2,
  p_cod_ext_carta          IN VARCHAR2,
  p_carta_acordo_id        OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE monojob_adicionar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_job_id                  IN job.job_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_jus_fornec_naohmlg      IN VARCHAR2,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_valor_fornecedor  IN VARCHAR2,
  p_vetor_valor_aprovado    IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao      IN VARCHAR2,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_carta_acordo_id         OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE multijob_adicionar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_job_id                  IN job.job_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_jus_fornec_naohmlg      IN VARCHAR2,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_flag_com_aprovacao      IN VARCHAR2,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_carta_acordo_id         OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_carta_acordo_id      IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id        IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id           IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id   IN carta_acordo.emp_faturar_por_id%TYPE,
  p_flag_mostrar_ac      IN carta_acordo.flag_mostrar_ac%TYPE,
  p_contato_fornec       IN carta_acordo.contato_fornec%TYPE,
  p_desc_item            IN VARCHAR2,
  p_valor_credito        IN VARCHAR2,
  p_perc_bv              IN VARCHAR2,
  p_motivo_atu_bv        IN VARCHAR2,
  p_perc_imposto         IN VARCHAR2,
  p_motivo_atu_imp       IN VARCHAR2,
  p_tipo_fatur_bv        IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_parc_datas     IN VARCHAR2,
  p_vetor_parc_num_dias  IN VARCHAR2,
  p_tipo_num_dias        IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores   IN VARCHAR2,
  p_condicao_pagto_id    IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto           IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id      IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia      IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta        IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta       IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar   IN VARCHAR2,
  p_instr_especiais      IN VARCHAR2,
  p_entre_data_prototipo IN VARCHAR2,
  p_entre_data_produto   IN VARCHAR2,
  p_entre_local          IN VARCHAR2,
  p_monta_hora_ini       IN VARCHAR2,
  p_monta_data_ini       IN VARCHAR2,
  p_monta_hora_fim       IN VARCHAR2,
  p_monta_data_fim       IN VARCHAR2,
  p_pserv_hora_ini       IN VARCHAR2,
  p_pserv_data_ini       IN VARCHAR2,
  p_pserv_hora_fim       IN VARCHAR2,
  p_pserv_data_fim       IN VARCHAR2,
  p_desmo_hora_ini       IN VARCHAR2,
  p_desmo_data_ini       IN VARCHAR2,
  p_desmo_hora_fim       IN VARCHAR2,
  p_desmo_data_fim       IN VARCHAR2,
  p_event_desc           IN VARCHAR2,
  p_event_local          IN VARCHAR2,
  p_event_hora_ini       IN VARCHAR2,
  p_event_data_ini       IN VARCHAR2,
  p_event_hora_fim       IN VARCHAR2,
  p_event_data_fim       IN VARCHAR2,
  p_produtor_id          IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta        IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE monojob_atualizar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_carta_acordo_id         IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_valor_fornecedor  IN VARCHAR2,
  p_vetor_valor_aprovado    IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE multijob_atualizar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_carta_acordo_id         IN carta_acordo.carta_acordo_id%TYPE,
  p_fornecedor_id           IN carta_acordo.fornecedor_id%TYPE,
  p_cliente_id              IN carta_acordo.cliente_id%TYPE,
  p_emp_faturar_por_id      IN carta_acordo.emp_faturar_por_id%TYPE,
  p_contato_fornec_id       IN carta_acordo.contato_fornec_id%TYPE,
  p_desc_item               IN VARCHAR2,
  p_valor_credito           IN VARCHAR2,
  p_perc_bv                 IN VARCHAR2,
  p_motivo_atu_bv           IN VARCHAR2,
  p_perc_imposto            IN VARCHAR2,
  p_motivo_atu_imp          IN VARCHAR2,
  p_tipo_fatur_bv           IN carta_acordo.tipo_fatur_bv%TYPE,
  p_vetor_item_id           IN VARCHAR2,
  p_vetor_tipo_produto_id   IN VARCHAR2,
  p_vetor_produto_fiscal_id IN VARCHAR2,
  p_vetor_quantidade        IN VARCHAR2,
  p_vetor_frequencia        IN VARCHAR2,
  p_vetor_custo_unitario    IN VARCHAR2,
  p_vetor_complemento       IN VARCHAR2,
  p_vetor_parc_datas        IN VARCHAR2,
  p_vetor_parc_num_dias     IN VARCHAR2,
  p_tipo_num_dias           IN parcela_carta.tipo_num_dias%TYPE,
  p_vetor_parc_valores      IN VARCHAR2,
  p_condicao_pagto_id       IN carta_acordo.condicao_pagto_id%TYPE,
  p_modo_pagto              IN carta_acordo.modo_pagto%TYPE,
  p_emp_fi_banco_id         IN carta_acordo.fi_banco_fornec_id%TYPE,
  p_emp_num_agencia         IN carta_acordo.num_agencia%TYPE,
  p_emp_num_conta           IN carta_acordo.num_conta%TYPE,
  p_emp_tipo_conta          IN carta_acordo.tipo_conta%TYPE,
  p_emp_flag_atualizar      IN VARCHAR2,
  p_instr_especiais         IN VARCHAR2,
  p_entre_data_prototipo    IN VARCHAR2,
  p_entre_data_produto      IN VARCHAR2,
  p_entre_local             IN VARCHAR2,
  p_monta_hora_ini          IN VARCHAR2,
  p_monta_data_ini          IN VARCHAR2,
  p_monta_hora_fim          IN VARCHAR2,
  p_monta_data_fim          IN VARCHAR2,
  p_pserv_hora_ini          IN VARCHAR2,
  p_pserv_data_ini          IN VARCHAR2,
  p_pserv_hora_fim          IN VARCHAR2,
  p_pserv_data_fim          IN VARCHAR2,
  p_desmo_hora_ini          IN VARCHAR2,
  p_desmo_data_ini          IN VARCHAR2,
  p_desmo_hora_fim          IN VARCHAR2,
  p_desmo_data_fim          IN VARCHAR2,
  p_event_desc              IN VARCHAR2,
  p_event_local             IN VARCHAR2,
  p_event_hora_ini          IN VARCHAR2,
  p_event_data_ini          IN VARCHAR2,
  p_event_hora_fim          IN VARCHAR2,
  p_event_data_fim          IN VARCHAR2,
  p_produtor_id             IN carta_acordo.produtor_id%TYPE,
  p_cod_ext_carta           IN VARCHAR2,
  p_vetor_sobra_item_id     IN VARCHAR2,
  p_vetor_sobra_valores     IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE emitida_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
  p_valor_fornecedor   IN VARCHAR2,
  p_tipo_fatur_bv      IN carta_acordo.tipo_fatur_bv%TYPE,
  p_perc_bv            IN VARCHAR2,
  p_perc_imposto       IN VARCHAR2,
  p_justificativa      IN VARCHAR2,
  p_vetor_item_nota_id IN VARCHAR2,
  p_vetor_valor_fornec IN VARCHAR2,
  p_vetor_valor_bv     IN VARCHAR2,
  p_vetor_valor_tip    IN VARCHAR2,
  p_historico_id       OUT historico.historico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE emitir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_pessoa_id         IN arquivo_pessoa.pessoa_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE email_registrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN email_carta.carta_acordo_id%TYPE,
  p_fornecedor_id     IN carta_acordo.fornecedor_id%TYPE,
  p_enviar_para       IN email_carta.enviar_para%TYPE,
  p_enviado_por       IN email_carta.enviado_por%TYPE,
  p_responder_para    IN email_carta.responder_para%TYPE,
  p_assunto           IN email_carta.assunto%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enviada_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_envio        IN carta_acordo.tipo_envio%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enviada_desmarcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE parcela_simular
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_valor_a_parcelar  IN VARCHAR2,
  p_vetor_num_parcela OUT VARCHAR2,
  p_vetor_data        OUT VARCHAR2,
  p_vetor_dia_semana  OUT VARCHAR2,
  p_vetor_perc        OUT VARCHAR2,
  p_vetor_valor       OUT VARCHAR2,
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
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_tipo_arq_ca       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aceite_registrar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aceite_desfazer
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN arquivo_carta.carta_acordo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE id_retornar
 (
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_num_job          IN VARCHAR2,
  p_num_carta_acordo IN VARCHAR2,
  p_carta_acordo_id  OUT carta_acordo.carta_acordo_id%TYPE,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 --
 FUNCTION numero_formatar(p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION num_orcam_retornar(p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION numero_completo_formatar
 (
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_flag_prefixo    IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 FUNCTION valor_retornar
 (
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION resultado_retornar(p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE) RETURN NUMBER;
 --
 FUNCTION legenda_retornar(p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION faixa_aprov_verificar
 (
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION faixa_aprov_id_retornar
 (
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN NUMBER;
 --
 FUNCTION usuario_aprov_verificar
 (
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION papel_priv_verificar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo_priv       IN privilegio.codigo%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE
 ) RETURN INTEGER;
 --
END; -- CARTA_ACORDO_PKG

/
