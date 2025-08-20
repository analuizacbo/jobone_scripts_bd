--------------------------------------------------------
--  DDL for Package NOTA_FISCAL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "NOTA_FISCAL_PKG" IS
 --
 PROCEDURE sub_itens_adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id         IN nota_fiscal.nota_fiscal_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE multijob_adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_valor_credito_usado    IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_arquivo_id_ext         IN VARCHAR2,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE auto_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id    OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id         IN nota_fiscal.nota_fiscal_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE atualizar_nfe
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
  p_emp_emissora_id    IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id     IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc            IN VARCHAR2,
  p_serie              IN nota_fiscal.serie%TYPE,
  p_tipo_pag_pessoa    IN nota_fiscal.tipo_pag_pessoa%TYPE,
  p_valor_mao_obra     IN VARCHAR2,
  p_data_entrada       IN VARCHAR2,
  p_data_emissao       IN VARCHAR2,
  p_data_pri_vencim    IN VARCHAR2,
  p_cliente_id         IN nota_fiscal.cliente_id%TYPE,
  p_emp_faturar_por_id IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_municipio_servico  IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico         IN nota_fiscal.uf_servico%TYPE,
  p_desc_servico       IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE completar
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id            IN nota_fiscal.nota_fiscal_id%TYPE,
  p_valor_mao_obra            IN VARCHAR2,
  p_valor_base_iss            IN VARCHAR2,
  p_valor_base_ir             IN VARCHAR2,
  p_desc_servico              IN VARCHAR2,
  p_produto_fiscal_id         IN nota_fiscal.produto_fiscal_id%TYPE,
  p_produto                   IN nota_fiscal.produto%TYPE,
  p_tipo_pag_pessoa           IN nota_fiscal.tipo_pag_pessoa%TYPE,
  p_cod_verificacao           IN nota_fiscal.cod_verificacao%TYPE,
  p_chave_acesso              IN nota_fiscal.chave_acesso%TYPE,
  p_modo_pagto                IN nota_fiscal.modo_pagto%TYPE,
  p_num_doc_pagto             IN nota_fiscal.num_doc_pagto%TYPE,
  p_emp_fi_banco_id           IN pessoa.fi_banco_id%TYPE,
  p_emp_num_agencia           IN pessoa.num_agencia%TYPE,
  p_emp_num_conta             IN pessoa.num_conta%TYPE,
  p_emp_tipo_conta            IN pessoa.tipo_conta%TYPE,
  p_emp_flag_atualizar        IN VARCHAR2,
  p_fi_banco_cobrador_id      IN nota_fiscal.fi_banco_cobrador_id%TYPE,
  p_vetor_data_vencim         IN VARCHAR2,
  p_vetor_valor_duplicata     IN VARCHAR2,
  p_vetor_fi_tipo_imposto     IN VARCHAR2,
  p_vetor_perc_imposto        IN VARCHAR2,
  p_fi_tipo_imposto_pessoa_id IN fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE,
  p_flag_reter_iss            IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_motivo_alt_aliquota       IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE apagar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fornecedor_adicionar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_emp2_apelido          IN pessoa.apelido%TYPE,
  p_emp2_nome             IN pessoa.nome%TYPE,
  p_emp2_flag_simples     IN VARCHAR2,
  p_emp2_flag_cpom        IN VARCHAR2,
  p_emp2_cnpj             IN pessoa.cnpj%TYPE,
  p_emp2_inscr_estadual   IN pessoa.inscr_estadual%TYPE,
  p_emp2_inscr_municipal  IN pessoa.inscr_municipal%TYPE,
  p_emp2_inscr_inss       IN pessoa.inscr_inss%TYPE,
  p_emp2_endereco         IN pessoa.endereco%TYPE,
  p_emp2_num_ender        IN pessoa.num_ender%TYPE,
  p_emp2_compl_ender      IN pessoa.compl_ender%TYPE,
  p_emp2_bairro           IN pessoa.bairro%TYPE,
  p_emp2_cep              IN pessoa.cep%TYPE,
  p_emp2_cidade           IN pessoa.cidade%TYPE,
  p_emp2_uf               IN pessoa.uf%TYPE,
  p_emp2_obs              IN pessoa.obs%TYPE,
  p_emp2_fi_banco_id      IN pessoa.fi_banco_id%TYPE,
  p_emp2_num_agencia      IN pessoa.num_agencia%TYPE,
  p_emp2_num_conta        IN pessoa.num_conta%TYPE,
  p_emp2_tipo_conta       IN pessoa.tipo_conta%TYPE,
  p_emp2_nome_titular     IN pessoa.nome_titular%TYPE,
  p_emp2_cnpj_cpf_titular IN pessoa.cnpj_cpf_titular%TYPE,
  p_emp2_perc_bv          IN VARCHAR2,
  p_emp2_tipo_fatur_bv    IN VARCHAR2,
  p_emp2_perc_imposto     IN VARCHAR2,
  p_fornecedor_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE receita_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_emp_patrocinio_id IN nota_fiscal.cliente_id%TYPE,
  p_tipo_receita      IN nota_fiscal.tipo_receita%TYPE,
  p_emp_receita_id    IN nota_fiscal.emp_receita_id%TYPE,
  p_resp_pgto_receita IN nota_fiscal.resp_pgto_receita%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE numero_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_num_doc_novo      IN nota_fiscal.num_doc%TYPE,
  p_serie_novo        IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE pagto_comandar
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id            IN nota_fiscal.nota_fiscal_id%TYPE,
  p_fi_banco_cobrador_id      IN nota_fiscal.fi_banco_cobrador_id%TYPE,
  p_vetor_data_vencim         IN VARCHAR2,
  p_vetor_valor_duplicata     IN VARCHAR2,
  p_vetor_fi_tipo_imposto     IN VARCHAR2,
  p_vetor_perc_imposto        IN VARCHAR2,
  p_fi_tipo_imposto_pessoa_id IN fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE,
  p_flag_reter_iss            IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_nota_fiscal_id    IN arquivo_nf.nota_fiscal_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
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
 PROCEDURE bv_comandar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nf_saida_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_fatur        IN VARCHAR2,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_num_doc           IN VARCHAR2,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_data_emissao      IN VARCHAR2,
  p_data_pri_vencim   IN VARCHAR2,
  p_valor_bruto       IN VARCHAR2,
  p_valor_mao_obra    IN VARCHAR2,
  p_nota_fiscal_id    OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nf_saida_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN VARCHAR2,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_valor_mao_obra    IN VARCHAR2,
  p_data_emissao      IN VARCHAR2,
  p_data_pri_vencim   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE nf_saida_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE dados_checkin_verificar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_valor_credito_usado    IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE nf_pagto_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_acao                 IN VARCHAR2,
  p_data_baixa           IN VARCHAR2,
  p_sequencia            IN VARCHAR2,
  p_nota_fiscal_id       IN VARCHAR2,
  p_saldo_bruto          IN VARCHAR2,
  p_saldo_liquido        IN VARCHAR2,
  p_tipo_baixa           IN VARCHAR2,
  p_valor_desconto       IN VARCHAR2,
  p_valor_juros          IN VARCHAR2,
  p_valor_liquido        IN VARCHAR2,
  p_valor_multa          IN VARCHAR2,
  p_data_lancamento      IN VARCHAR2,
  p_nota_fiscal_pagto_id OUT nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE nf_pagto_adicionar_manual
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id       IN VARCHAR2,
  p_data_baixa           IN VARCHAR2,
  p_tipo_baixa           IN VARCHAR2,
  p_acao                 IN VARCHAR2,
  p_valor                IN VARCHAR2,
  p_valor_multa          IN VARCHAR2,
  p_valor_juros          IN VARCHAR2,
  p_nota_fiscal_pagto_id OUT nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE nf_saldo_atualizar
 (
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
  p_saldo_liquido  IN VARCHAR2,
  p_saldo_bruto    IN VARCHAR2,
  p_flag_commit    IN VARCHAR2,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 );
 --
 FUNCTION valor_retornar
 (
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
  p_tipo_valor     IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_checkin_pend_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION data_pri_vencim_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN DATE;
 --
 FUNCTION flag_pago_cliente_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION flag_com_fatur_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION tipo_item_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION tipo_fatur_bv_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE)
  RETURN VARCHAR2;
 --
 FUNCTION data_fatur_bv_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN DATE;
 --
 FUNCTION bv_faturado_verificar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN INTEGER;
 --
 FUNCTION bv_comandado_verificar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN INTEGER;
 --
 FUNCTION bv_nf_saida_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE) RETURN NUMBER;
 --
 FUNCTION chave_acesso_verificar(p_chave_acesso IN VARCHAR2) RETURN NUMBER;
 --
END; -- NOTA_FISCAL_PKG

/
