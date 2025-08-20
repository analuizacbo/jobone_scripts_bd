--------------------------------------------------------
--  DDL for Package CONTRATO_FISICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CONTRATO_FISICO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_data_prazo        IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE desc_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_descricao          IN contrato_fisico.descricao%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE acao_executar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN contrato.empresa_id%TYPE,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_cod_acao           IN ct_transicao.cod_acao%TYPE,
  p_descricao          IN contrato_fisico.descricao%TYPE,
  p_motivo             IN contrato_fisico.motivo%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN NUMBER,
  p_contrato_fisico_id IN contrato_fisico.contrato_fisico_id%TYPE,
  p_tipo_arq_fisico    IN arquivo_contrato_fisico.tipo_arq_fisico%TYPE,
  p_arquivo_id         IN arquivo.arquivo_id%TYPE,
  p_volume_id          IN arquivo.volume_id%TYPE,
  p_descricao          IN arquivo.descricao%TYPE,
  p_nome_original      IN arquivo.nome_original%TYPE,
  p_nome_fisico        IN arquivo.nome_fisico%TYPE,
  p_mime_type          IN arquivo.mime_type%TYPE,
  p_tamanho            IN arquivo.tamanho%TYPE,
  p_palavras_chave     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
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
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN contrato.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
END; -- CONTRATO_FISICO_PKG


/
