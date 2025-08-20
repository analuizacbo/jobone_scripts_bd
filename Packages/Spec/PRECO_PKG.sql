--------------------------------------------------------
--  DDL for Package PRECO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PRECO_PKG" IS
 --
 --
 PROCEDURE tab_preco_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cliente_id           IN tab_preco.cliente_id%TYPE,
  p_grupo_id             IN tab_preco.grupo_id%TYPE,
  p_nome                 IN tab_preco.nome%TYPE,
  p_tabela_preco_base_id IN tab_preco.tabela_preco_base_id%TYPE,
  p_data_referencia      IN VARCHAR2,
  p_data_validade        IN VARCHAR2,
  p_flag_padrao          IN tab_preco.flag_padrao%TYPE,
  p_perc_acres_cargo     IN VARCHAR2,
  p_perc_acres_tipo_prod IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE tab_preco_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cliente_id        IN tab_preco.cliente_id%TYPE,
  p_grupo_id          IN tab_preco.grupo_id%TYPE,
  p_nome              IN tab_preco.nome%TYPE,
  p_data_referencia   IN VARCHAR2,
  p_data_validade     IN VARCHAR2,
  p_flag_pode_precif  IN tab_preco.flag_pode_precif%TYPE,
  p_flag_pode_ganhar  IN tab_preco.flag_pode_ganhar%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE tab_preco_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE tab_preco_acao_arquivo
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_acao              IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_cargo_vincular
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_vetor_preco_id       IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_cargo_associar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_cargo_desassociar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_cargo_alterar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_preco_id             IN tab_preco.preco_id%TYPE,
  p_nome_alternativo     IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE tab_preco_percent_aplicar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_preco_id             IN tab_preco.preco_id%TYPE,
  p_perc_acres_cargo     IN VARCHAR2,
  p_perc_acres_tipo_prod IN VARCHAR2,
  p_flag_commit          IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE tipo_produto_vincular
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_vetor_preco_id    IN VARCHAR2,
  p_custo             VARCHAR2,
  p_preco             VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE tipo_produto_preco_associar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE tipo_produto_preco_desassociar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE tipo_produto_preco_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_custo             IN VARCHAR2,
  p_preco             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE xml_gerar
 (
  p_preco_id IN tab_preco.preco_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );

END; -- PRECO_PKG

/
