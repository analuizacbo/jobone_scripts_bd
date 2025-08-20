--------------------------------------------------------
--  DDL for Package RELATORIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "RELATORIO_PKG" IS
 --
 PROCEDURE os_tline_processar
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE os_tline_processar_iniciar
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE os_tline_processar_depend
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE os_tline_processar_espacos
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE rentab_job_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fluxo_checkin_processar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_data_ini             IN VARCHAR2,
  p_data_fim             IN VARCHAR2,
  p_rel_fluxo_checkin_id OUT rel_fluxo_checkin.rel_fluxo_checkin_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE apontam_mensal_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_jobs              IN VARCHAR2,
  p_rel_apon_mens_id  OUT rel_apon_mens_val.rel_apon_mens_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE limpar;
 --
--
END; --  RELATORIO_PKG

/
