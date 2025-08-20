--------------------------------------------------------
--  DDL for Package TIPO_PRODUTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_PRODUTO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_nome              IN tipo_produto.nome%TYPE,
  p_categoria_id      IN tipo_produto.categoria_id%TYPE,
  p_cod_ext_produto   IN tipo_produto.cod_ext_produto%TYPE,
  p_variacoes         IN VARCHAR2,
  p_vetor_tipo_os     IN VARCHAR2,
  p_tempo_exec_info   IN VARCHAR2,
  p_flag_ativo        IN tipo_produto.flag_ativo%TYPE,
  p_flag_tarefa       IN tipo_produto.flag_tarefa%TYPE,
  p_unidade_freq      IN tipo_produto.unidade_freq%TYPE,
  p_vetor_preco_id    IN VARCHAR2,
  p_custo             IN VARCHAR2,
  p_preco             IN VARCHAR2,
  p_tipo_produto_id   OUT tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_nome              IN tipo_produto.nome%TYPE,
  p_categoria_id      IN tipo_produto.categoria_id%TYPE,
  p_cod_ext_produto   IN tipo_produto.cod_ext_produto%TYPE,
  p_variacoes         IN VARCHAR2,
  p_vetor_tipo_os     IN VARCHAR2,
  p_tempo_exec_info   IN VARCHAR2,
  p_flag_ativo        IN tipo_produto.flag_ativo%TYPE,
  p_flag_tarefa       IN tipo_produto.flag_tarefa%TYPE,
  p_unidade_freq      IN tipo_produto.unidade_freq%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tipo_produto_id_old IN tipo_produto.tipo_produto_id%TYPE,
  p_tipo_produto_id_new IN tipo_produto.tipo_produto_id%TYPE,
  p_flag_concat_complem IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE texto_tratar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_texto             IN VARCHAR2,
  p_tipo_produto_id   OUT tipo_produto.tipo_produto_id%TYPE,
  p_complemento       OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE tempo_gasto_calcular;
 --
 PROCEDURE xml_gerar
 (
  p_tipo_produto_id IN tipo_produto.tipo_produto_id%TYPE,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 --
 FUNCTION id_retornar
 (
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_texto      IN VARCHAR
 ) RETURN INTEGER;
 --
 --
 PROCEDURE duplicar
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN empresa.empresa_id%TYPE,
  p_nome                     IN tipo_produto.nome%TYPE,
  p_cod_ext_produto          IN tipo_produto.cod_ext_produto%TYPE,
  p_tipo_produto_duplicar_id IN tipo_produto.tipo_produto_id%TYPE,
  p_vetor_preco_id           IN VARCHAR2,
  p_custo                    IN VARCHAR2,
  p_preco                    IN VARCHAR2,
  p_tipo_produto_id          OUT tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 );
 --
 PROCEDURE categoria_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_classe_produto_id IN NUMBER,
  p_descricao         IN VARCHAR2,
  p_cod_ext           IN VARCHAR2,
  p_cod_acao_os       IN VARCHAR2,
  p_tipo_entregavel   IN VARCHAR2,
  p_flag_tp_midia_on  IN VARCHAR2,
  p_flag_tp_midia_off IN VARCHAR2,
  p_flag_entregue_cli IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_categoria_id      OUT NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE categoria_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_categoria_id      IN NUMBER,
  p_classe_produto_id NUMBER,
  p_flag_ativo        IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_cod_ext           IN VARCHAR2,
  p_cod_acao_os       IN VARCHAR2,
  p_tipo_entregavel   IN VARCHAR2,
  p_flag_tp_midia_on  IN VARCHAR2,
  p_flag_tp_midia_off IN VARCHAR2,
  p_flag_entregue_cli IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE categoria_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_categoria_id      IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
END;

/
