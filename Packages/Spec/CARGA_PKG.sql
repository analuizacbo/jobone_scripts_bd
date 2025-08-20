--------------------------------------------------------
--  DDL for Package CARGA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CARGA_PKG" IS
 --
 PROCEDURE pessoa_carregar
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_vetor_job_pdv           IN VARCHAR2,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE usuario_carregar
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
 PROCEDURE tipo_produto_carregar
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 );
 --
--
END; -- CARGA_pkg

/
