--------------------------------------------------------
--  DDL for Package APONTAM_PROGR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APONTAM_PROGR_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_hora_ini           IN VARCHAR2,
  p_data_fim           IN VARCHAR2,
  p_hora_fim           IN VARCHAR2,
  p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
  p_obs                IN VARCHAR2,
  p_flag_os_aprov_auto IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_apontam_progr_id   IN apontam_progr.apontam_progr_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_hora_ini           IN VARCHAR2,
  p_data_fim           IN VARCHAR2,
  p_hora_fim           IN VARCHAR2,
  p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
  p_obs                IN VARCHAR2,
  p_flag_os_aprov_auto IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_apontam_progr_id  IN apontam_progr.apontam_progr_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_apontam_progr_id IN apontam_progr.apontam_progr_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
END; -- APONTAM_PROGR_PKG


/
