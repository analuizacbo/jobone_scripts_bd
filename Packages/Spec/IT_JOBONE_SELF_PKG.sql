--------------------------------------------------------
--  DDL for Package IT_JOBONE_SELF_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_JOBONE_SELF_PKG" IS
 --
 PROCEDURE oportunidade_job_adicionar
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_flag_commit     IN VARCHAR2,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 PROCEDURE oportunidade_job_status_atu
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 PROCEDURE oportunidade_job_adicionar_todos
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 PROCEDURE oportunidade_job_reenderecar_todos
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
END; -- IT_JOBONE_SELF_PKG

/
