--------------------------------------------------------
--  DDL for Package FATURAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FATURAMENTO_PKG" IS
 --
 PROCEDURE comandar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_job_id                IN faturamento.job_id%TYPE,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_carta_acordo_id IN VARCHAR2,
  p_vetor_nota_fiscal_id  IN VARCHAR2,
  p_vetor_valor_fatura    IN VARCHAR2,
  p_emp_faturar_por_id    IN faturamento.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper     IN faturamento.cod_natureza_oper%TYPE,
  p_ordem_compra          IN faturamento.ordem_compra%TYPE,
  p_cliente_id            IN faturamento.cliente_id%TYPE,
  p_contato_cli_id        IN faturamento.contato_cli_id%TYPE,
  p_produto_cliente_id    IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim           IN VARCHAR2,
  p_num_parcela           IN VARCHAR2,
  p_descricao             IN VARCHAR2,
  p_obs                   IN VARCHAR2,
  p_flag_patrocinio       IN VARCHAR2,
  p_flag_outras_receitas  IN VARCHAR2,
  p_tipo_receita          IN VARCHAR2,
  p_municipio_servico     IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico            IN nota_fiscal.uf_servico%TYPE,
  p_faturamento_id        OUT faturamento.faturamento_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE bv_gerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_flag_comandar     IN VARCHAR2,
  p_faturamento_id    OUT faturamento.faturamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE bv_cancelar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE bv_comandar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_emp_faturar_por_id IN faturamento.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper  IN faturamento.cod_natureza_oper%TYPE,
  p_produto_cliente_id IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_emp_faturar_por_id IN faturamento.emp_faturar_por_id%TYPE,
  p_cliente_id         IN faturamento.cliente_id%TYPE,
  p_contato_cli_id     IN faturamento.contato_cli_id%TYPE,
  p_produto_cliente_id IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim        IN VARCHAR2,
  p_descricao          IN faturamento.descricao%TYPE,
  p_obs                IN faturamento.obs%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE receita_atualizar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_faturamento_id       IN VARCHAR2,
  p_flag_patrocinio      IN VARCHAR2,
  p_flag_outras_receitas IN VARCHAR2,
  p_tipo_receita         IN VARCHAR2,
  p_justificativa        IN VARCHAR2,
  p_historico_id         OUT historico.historico_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_faturamento_id IN faturamento.faturamento_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 );
 --
 --
 FUNCTION valor_fatura_retornar(p_faturamento_id IN faturamento.faturamento_id%TYPE) RETURN NUMBER;
 --
 FUNCTION valor_retornar
 (
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_na_nf_retornar
 (
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id  IN nota_fiscal.nota_fiscal_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION valor_orcam_retornar
 (
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_valor   IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION data_fechamento_retornar(p_orcamento_id IN orcamento.orcamento_id%TYPE) RETURN DATE;
 --
 FUNCTION itens_retornar(p_faturamento_id IN faturamento.faturamento_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION nf_fornec_id_retornar(p_faturamento_id IN faturamento.faturamento_id%TYPE) RETURN INTEGER;
 --
END; -- FATURAMENTO_PKG

/
