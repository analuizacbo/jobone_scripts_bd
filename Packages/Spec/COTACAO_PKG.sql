--------------------------------------------------------
--  DDL for Package COTACAO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "COTACAO_PKG" IS 
--
FUNCTION numero_formatar(p_cotacao_id IN cotacao.cotacao_id%TYPE) RETURN VARCHAR2;
--
--
PROCEDURE cotacao_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_item_id           IN NUMBER,
  p_cotacao_id        OUT cotacao.cotacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
PROCEDURE cotacao_info_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_info_adicional    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
 PROCEDURE cotacao_prazo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_data_prazo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
 PROCEDURE fornecedor_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_pessoa_id         IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
 PROCEDURE cotacao_item_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_vetor_item_id     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
PROCEDURE cotacao_item_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_cotacao_item_id   IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
--
END; --COTACAO_PKG

/
