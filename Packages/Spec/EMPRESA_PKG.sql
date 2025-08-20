--------------------------------------------------------
--  DDL for Package EMPRESA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "EMPRESA_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_nome              IN empresa.nome%TYPE,
  p_codigo            IN empresa.codigo%TYPE,
  p_cod_ext_empresa   IN empresa.cod_ext_empresa%TYPE,
  p_pais_id           IN pais.pais_id%TYPE,
  p_localidade        IN VARCHAR2,
  p_empresa_id        OUT empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN empresa.nome%TYPE,
  p_codigo            IN empresa.codigo%TYPE,
  p_cod_ext_empresa   IN empresa.cod_ext_empresa%TYPE,
  p_pais_id           IN pais.pais_id%TYPE,
  p_localidade        IN VARCHAR2,
  p_flag_ativo        IN empresa.flag_ativo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
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
  p_empresa_arq_id    IN arquivo_empresa.empresa_id%TYPE,
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
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE parametro_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa_parametro.empresa_id%TYPE,
  p_parametro_id      IN empresa_parametro.parametro_id%TYPE,
  p_valor_parametro   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 FUNCTION parametro_retornar
 (
  p_empresa_id     IN empresa.empresa_id%TYPE,
  p_nome_parametro IN parametro.nome%TYPE
 ) RETURN VARCHAR2;
 --
 FUNCTION servidor_arquivo_retornar
 (
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_job_id     IN job.job_id%TYPE
 ) RETURN NUMBER;
 --
END; -- empresa_pkg

/
