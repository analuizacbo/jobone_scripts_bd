--------------------------------------------------------
--  DDL for Package ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "ITEM_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_orcamento_id           IN item.orcamento_id%TYPE,
  p_tipo_produto_id        IN item.tipo_produto_id%TYPE,
  p_fornecedor_id          IN item.fornecedor_id%TYPE,
  p_grupo                  IN VARCHAR2,
  p_subgrupo               IN VARCHAR2,
  p_complemento            IN item.complemento%TYPE,
  p_tipo_item              IN item.tipo_item%TYPE,
  p_flag_sem_valor         IN item.flag_sem_valor%TYPE,
  p_flag_com_honor         IN item.flag_com_honor%TYPE,
  p_flag_com_encargo       IN item.flag_com_encargo%TYPE,
  p_flag_com_encargo_honor IN item.flag_com_encargo_honor%TYPE,
  p_flag_pago_cliente      IN item.flag_pago_cliente%TYPE,
  p_quantidade             IN VARCHAR2,
  p_frequencia             IN VARCHAR2,
  p_unidade_freq           IN item.unidade_freq%TYPE,
  p_custo_unitario         IN VARCHAR2,
  p_valor_fornecedor       IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_tipo_fatur_bv          IN item.tipo_fatur_bv%TYPE,
  p_obs                    IN VARCHAR2,
  p_cod_ext                IN VARCHAR2,
  p_item_id                OUT item.item_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_item_id                IN item.item_id%TYPE,
  p_tipo_produto_id        IN item.tipo_produto_id%TYPE,
  p_fornecedor_id          IN item.fornecedor_id%TYPE,
  p_grupo                  IN item.grupo%TYPE,
  p_subgrupo               IN item.subgrupo%TYPE,
  p_complemento            IN item.complemento%TYPE,
  p_tipo_item              IN item.tipo_item%TYPE,
  p_flag_sem_valor         IN item.flag_sem_valor%TYPE,
  p_flag_com_honor         IN item.flag_com_honor%TYPE,
  p_flag_com_encargo       IN item.flag_com_encargo%TYPE,
  p_flag_com_encargo_honor IN item.flag_com_encargo_honor%TYPE,
  p_flag_pago_cliente      IN item.flag_pago_cliente%TYPE,
  p_quantidade             IN VARCHAR2,
  p_frequencia             IN VARCHAR2,
  p_unidade_freq           IN item.unidade_freq%TYPE,
  p_custo_unitario         IN VARCHAR2,
  p_valor_fornecedor       IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_tipo_fatur_bv          IN item.tipo_fatur_bv%TYPE,
  p_obs                    IN VARCHAR2,
  p_cod_ext                IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE tipo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_complemento       IN item.complemento%TYPE,
  p_tipo_produto_id   IN item.tipo_produto_id%TYPE,
  p_novo_tipo_produto IN tipo_produto.nome%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE valores_recalcular
 (
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ordem_compra_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_ordem_compra      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ordem_retornar
 (
  p_usuario_sessao_id IN NUMBER,
  p_job_id            IN item.job_id%TYPE,
  p_orcamento_id      IN item.orcamento_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo          IN item.subgrupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_ordem_grupo       OUT item.ordem_grupo%TYPE,
  p_ordem_subgrupo    OUT item.ordem_subgrupo%TYPE,
  p_ordem_item        OUT item.ordem_item%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE historico_gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_codigo            IN item_hist.codigo%TYPE,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cod_externo_alterar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_cod_externo       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_item_id  IN item.item_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 FUNCTION liberacao_especial_verificar(p_item_id IN item.item_id%TYPE) RETURN INTEGER;
 --
 FUNCTION data_evento_retornar
 (
  p_item_id IN item.item_id%TYPE,
  p_codigo  IN item_hist.codigo%TYPE
 ) RETURN DATE;
 --
 FUNCTION valor_retornar
 (
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_natureza_retornar
 (
  p_item_id       IN item.item_id%TYPE,
  p_natureza_calc IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_sobra_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_sobra IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_planejado_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_utilizado_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_reservado_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_liberado_b_retornar(p_item_id IN item.item_id%TYPE) RETURN NUMBER;
 --
 FUNCTION valor_disponivel_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_na_nf_retornar
 (
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id  IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN NUMBER;
 --
 FUNCTION valor_checkin_pend_retornar(p_item_id IN item.item_id%TYPE) RETURN NUMBER;
 --
 FUNCTION valor_realizado_retornar
 (
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION parcelado_verificar(p_item_id IN item.item_id%TYPE) RETURN INTEGER;
 --
 FUNCTION qtd_carta_acordo_retornar(p_item_id IN item.item_id%TYPE) RETURN INTEGER;
 --
 FUNCTION carta_acordo_ok_verificar(p_item_id IN item.item_id%TYPE) RETURN INTEGER;
 --
 FUNCTION nome_item_retornar(p_item_id IN item.item_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION num_item_retornar
 (
  p_item_id      IN item.item_id%TYPE,
  p_flag_com_job IN VARCHAR2
 ) RETURN VARCHAR2;
 --
END; -- ITEM_PKG

/
