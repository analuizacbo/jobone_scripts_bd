--------------------------------------------------------
--  DDL for Package FATURAMENTO_CTR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FATURAMENTO_CTR_PKG" IS
 --
 PROCEDURE comandar
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_contrato_id               IN faturamento_ctr.contrato_id%TYPE,
  p_vetor_parcela_contrato_id IN VARCHAR2,
  p_vetor_valor_fatura        IN VARCHAR2,
  p_emp_faturar_por_id        IN faturamento_ctr.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper         IN faturamento_ctr.cod_natureza_oper%TYPE,
  p_ordem_compra              IN faturamento.ordem_compra%TYPE,
  p_cliente_id                IN faturamento_ctr.cliente_id%TYPE,
  p_contato_cli_id            IN faturamento_ctr.contato_cli_id%TYPE,
  p_data_vencim               IN VARCHAR2,
  p_descricao                 IN VARCHAR2,
  p_obs                       IN VARCHAR2,
  p_flag_patrocinio           IN VARCHAR2,
  p_flag_outras_receitas      IN VARCHAR2,
  p_tipo_receita              IN VARCHAR2,
  p_municipio_servico         IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico                IN nota_fiscal.uf_servico%TYPE,
  p_flag_pula_integr          IN VARCHAR2,
  p_faturamento_ctr_id        OUT faturamento_ctr.faturamento_ctr_id%TYPE,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE,
  p_xml                OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 FUNCTION valor_fatura_retornar(p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION parcelas_retornar(p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE)
  RETURN VARCHAR2;
 --
END; -- FATURAMENTO_CTR_PKG

/
