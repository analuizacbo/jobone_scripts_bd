--------------------------------------------------------
--  DDL for Package CENARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CENARIO_PKG" IS
 --
 PROCEDURE consistir_cenario
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_chamada      IN VARCHAR2,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_nome_cenario      IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_nome              IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_briefing          IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_cenario_id        OUT cenario.cenario_id%TYPE,
  p_etapa             OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_nome              IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_briefing          IN CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_duplicar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_padrao_marcar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_recalcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_id         IN cenario.cenario_id%TYPE,
  p_servico_id         IN servico.servico_id%TYPE,
  p_descricao          IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_escopo             IN VARCHAR2,
  p_mes_ano_inicio     IN VARCHAR2,
  p_cenario_servico_id OUT cenario_servico.cenario_servico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_descricao          IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_escopo             IN VARCHAR2,
  p_mes_ano_inicio     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_excluir
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_duplicar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_id         IN cenario.cenario_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_horas_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_area_id            IN area.area_id%TYPE,
  p_cargo_id           IN cargo.cargo_id%TYPE,
  p_nivel              IN VARCHAR2,
  p_nome_alternativo   IN VARCHAR2,
  p_hora_mes           IN VARCHAR2,
  p_horas_totais       IN VARCHAR2,
  p_custo_hora         IN VARCHAR2,
  p_custo_total        IN VARCHAR2,
  p_preco_venda        IN VARCHAR2,
  p_preco_final        IN VARCHAR2,
  p_custo              IN VARCHAR2,
  p_overhead           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_horas_atualizar
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_area_id                  IN area.area_id%TYPE,
  p_cargo_id                 IN cargo.cargo_id%TYPE,
  p_nivel                    IN VARCHAR2,
  p_nome_alternativo         IN VARCHAR2,
  p_hora_mes                 IN VARCHAR2,
  p_horas_totais             IN VARCHAR2,
  p_custo_hora               IN VARCHAR2,
  p_custo_total              IN VARCHAR2,
  p_preco_venda              IN VARCHAR2,
  p_preco_final              IN VARCHAR2,
  p_custo                    IN VARCHAR2,
  p_overhead                 IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_horas_excluir
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_horas_duplicar
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_cenario_servico_id       IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit              IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_horas_recalcular
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_desconto           IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_item_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_tipo_produto_id    IN tipo_produto.tipo_produto_id%TYPE,
  p_fornecedor_id      IN pessoa.pessoa_id%TYPE,
  p_complemento        IN VARCHAR2,
  p_custo_unitario     IN VARCHAR2,
  p_quantidade         IN VARCHAR2,
  p_frequencia         IN VARCHAR2,
  p_unidade            IN VARCHAR2,
  p_custo_total        IN VARCHAR2,
  p_honorarios         IN VARCHAR2,
  p_taxas              IN VARCHAR2,
  p_preco_venda        IN VARCHAR2,
  p_preco_final        IN VARCHAR2,
  p_mod_contr          IN VARCHAR2,
  p_honorario_perc     IN VARCHAR2,
  p_taxa_perc          IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_item_atualizar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_tipo_produto_id         IN tipo_produto.tipo_produto_id%TYPE,
  p_fornecedor_id           IN pessoa.pessoa_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_custo_unitario          IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_frequencia              IN VARCHAR2,
  p_unidade                 IN VARCHAR2,
  p_custo_total             IN VARCHAR2,
  p_honorarios              IN VARCHAR2,
  p_taxas                   IN VARCHAR2,
  p_preco_venda             IN VARCHAR2,
  p_preco_final             IN VARCHAR2,
  p_mod_contr               IN VARCHAR2,
  p_honorario_perc          IN VARCHAR2,
  p_taxa_perc               IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_item_excluir
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_item_duplicar
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_cenario_servico_id      IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit             IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_usu_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_item_recalcular
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_honorario          IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE cenario_servico_usu_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_servico_usu_id    IN cenario_servico_usu.cenario_servico_usu_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 /*PROCEDURE enderecar_manual
 (
   p_usuario_sessao_id IN NUMBER
  ,p_empresa_id        IN oportunidade.empresa_id%TYPE
  ,p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE
  ,p_area_id           IN papel.area_id%TYPE
  ,p_vetor_usuarios    IN VARCHAR2
  ,p_erro_cod          OUT VARCHAR2
  ,p_erro_msg          OUT VARCHAR2
 );*/
 --
 --
 PROCEDURE arquivo_cenario_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_cenario_id        IN arquivo_cenario.cenario_id%TYPE,
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
 --
 PROCEDURE arquivo_cenario_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE xml_gerar
 (
  p_cenario_id IN cenario.cenario_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE cenario_status_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cenario_servico_status_alterar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_cod_acao           IN tipo_acao.codigo%TYPE,
  p_motivo             IN VARCHAR2,
  p_complemento        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE cenario_aprov_rc_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE interacao_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_interacao_id      OUT interacao.interacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
END; --CENARIO_PKG;

/
